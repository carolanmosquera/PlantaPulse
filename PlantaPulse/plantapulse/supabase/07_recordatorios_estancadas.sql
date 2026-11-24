-- ════════════════════════════════════════════════════════════════════
-- PlantaPulse — recordatorio de órdenes críticas estancadas (KAN-95)
-- Ejecutar ENTERO en el SQL Editor. Idempotente.
-- ════════════════════════════════════════════════════════════════════
--
-- Cada 15 minutos la base revisa las órdenes críticas. Si una lleva más
-- de 4 horas sin reportes, le pide a la Edge Function 'enviar-push' que
-- avise a los supervisores de esa planta (la misma función de KAN-97).
--
-- Requisitos (los mismos de KAN-97, ver supabase/functions/enviar-push/README.md):
--   * la función enviar-push desplegada con sus secretos
--   * el secreto 'push_webhook_secret' guardado en el Vault
-- Sin ese secreto, la revisión no hace nada.
--
-- Qué es una orden estancada:
--   * crítica: prioridad 'critica' (Urgente) o estado 'critica'
--   * abierta: ni en validación ni completada, y no eliminada
--   * su último reporte (o su creación, si no tiene) fue hace más de 4 h
--   * no se le ha recordado desde ese último reporte, o el último
--     recordatorio fue hace más de 4 h (si sigue igual, se repite)

create extension if not exists pg_net with schema extensions;
-- En Supabase, pg_cron también se puede activar en Integrations > Cron.
create extension if not exists pg_cron;

-- ─── Cuándo se recordó cada orden ───────────────────────────────────
-- Tabla aparte y no una columna de 'ordenes': cualquier cambio a una
-- orden mueve su ultima_actividad (trigger proteger_ordenes), y un
-- recordatorio no es un avance del trabajo.
create table if not exists recordatorios_estancadas (
  orden_id uuid primary key references ordenes(id) on delete cascade,
  enviado_en timestamptz not null default now()
);

-- Solo la usa el servidor (service_role): la app no la lee ni la escribe
alter table recordatorios_estancadas enable row level security;

-- ─── Qué órdenes están estancadas ───────────────────────────────────
create or replace function public.ordenes_estancadas(horas int default 4)
returns table (
  id uuid,
  codigo text,
  titulo text,
  planta_id text,
  prioridad text,
  estado text,
  ultimo_avance timestamptz
)
language sql stable security definer set search_path = '' as $$
  select o.id, o.codigo, o.titulo, o.planta_id, o.prioridad, o.estado, a.ultimo_avance
    from public.ordenes o
    cross join lateral (
      select coalesce(max(r.created_at), o.created_at) as ultimo_avance
        from public.reportes r
       where r.orden_id = o.id
    ) a
    left join public.recordatorios_estancadas re on re.orden_id = o.id
   where o.eliminada_en is null
     and (o.prioridad = 'critica' or o.estado = 'critica')
     and o.estado not in ('validando', 'completada')
     and a.ultimo_avance < now() - make_interval(hours => horas)
     and (re.enviado_en is null
          or re.enviado_en < a.ultimo_avance
          or re.enviado_en < now() - make_interval(hours => horas))
   order by a.ultimo_avance;
$$;

revoke execute on function public.ordenes_estancadas(int) from public, anon, authenticated;
grant execute on function public.ordenes_estancadas(int) to service_role;

-- ─── La revisión: llama a la Edge Function ──────────────────────────
create or replace function public.revisar_ordenes_estancadas() returns void
language plpgsql security definer set search_path = '' as $$
declare
  secreto text;
begin
  select decrypted_secret into secreto
    from vault.decrypted_secrets
   where name = 'push_webhook_secret';
  if secreto is null then
    return;
  end if;

  -- Si no hay ninguna orden estancada, ni siquiera se llama a la función
  if not exists (select 1 from public.ordenes_estancadas(4)) then
    return;
  end if;

  perform net.http_post(
    url     := 'https://uxajglpaoofragjxcrvx.supabase.co/functions/v1/enviar-push',
    body    := jsonb_build_object('tipo', 'estancadas'),
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-webhook-secret', secreto)
  );
end $$;

revoke execute on function public.revisar_ordenes_estancadas() from public, anon, authenticated;

-- ─── Cada 15 minutos ────────────────────────────────────────────────
-- Con el mismo nombre, cron.schedule reemplaza la tarea si ya existía.
select cron.schedule(
  'recordatorios-ordenes-estancadas',
  '*/15 * * * *',
  'select public.revisar_ordenes_estancadas()'
);

-- Para apagarla:   select cron.unschedule('recordatorios-ordenes-estancadas');
-- Para revisar ya: select public.revisar_ordenes_estancadas();
-- Ver qué saldría: select * from public.ordenes_estancadas(4);
