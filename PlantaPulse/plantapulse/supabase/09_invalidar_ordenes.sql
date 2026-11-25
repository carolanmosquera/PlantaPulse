-- ════════════════════════════════════════════════════════════════════
-- PlantaPulse — invalidar órdenes (solo admin)
-- Ejecutar después de esquema.sql, 02_eliminar_ordenes.sql y
-- 07_recordatorios_estancadas.sql. Idempotente y en una transacción:
-- si algo falla, no se aplica nada.
-- ════════════════════════════════════════════════════════════════════
--
-- Para qué: hay órdenes que ya tienen reportes (no se pueden eliminar,
-- y está bien: eliminar_orden() lo prohíbe para no perder historial),
-- pero que eran falsas o de prueba. Invalidarla:
--   - la saca del feed, de Mis Tareas y del resumen;
--   - la deja visible en el Historial (supervisores y admin), marcada;
--   - la congela: ya no se edita, no se reasigna ni recibe reportes;
--   - guarda quién la invalidó, cuándo y por qué. No se borra nada.

begin;

-- ─── Quién, cuándo y por qué ────────────────────────────────────────
alter table public.ordenes add column if not exists invalidada_en timestamptz;
alter table public.ordenes add column if not exists invalidada_por jsonb;
alter table public.ordenes add column if not exists motivo_invalidacion text;

-- ─── La invalidación ────────────────────────────────────────────────
create or replace function public.invalidar_orden(
  p_orden_id uuid,
  p_motivo text
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  o public.ordenes%rowtype;
  v_motivo text := regexp_replace(coalesce(p_motivo, ''),
                                  '^[[:space:]]+|[[:space:]]+$', '', 'g');
  v_quien jsonb;
begin
  if not public.soy_admin() then
    raise exception 'Solo un administrador puede invalidar órdenes.'
      using errcode = '42501';
  end if;
  if length(v_motivo) not between 5 and 300 then
    raise exception 'Escribe el motivo de la invalidación (de 5 a 300 caracteres).';
  end if;

  select * into o from public.ordenes where id = p_orden_id for update;
  if not found or o.planta_id is distinct from public.mi_planta() then
    raise exception 'La orden no existe.' using errcode = 'P0002';
  end if;
  if o.eliminada_en is not null then
    raise exception 'La orden fue eliminada: no hace falta invalidarla.';
  end if;
  -- Idempotente: pulsar dos veces no es un error, y se conserva la
  -- firma de la primera invalidación
  if o.invalidada_en is not null then
    return;
  end if;

  select jsonb_build_object('uid', u.id, 'nombre', u.nombre, 'fotoUrl', u.foto_url)
    into v_quien
    from public.usuarios u where u.id = auth.uid();

  update public.ordenes
     set invalidada_en = now(),
         invalidada_por = v_quien,
         motivo_invalidacion = v_motivo
   where id = p_orden_id;
end $$;

revoke execute on function public.invalidar_orden(uuid, text) from public, anon;
grant execute on function public.invalidar_orden(uuid, text) to authenticated;

-- ─── La app no puede tocar una orden invalidada ─────────────────────
-- Es la misma función de 02_eliminar_ordenes.sql con dos agregados:
-- una orden invalidada ya no se modifica, y las columnas de la
-- invalidación solo las pone invalidar_orden().
create or replace function public.proteger_ordenes() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon') then
    if old.eliminada_en is not null then
      raise exception 'La orden fue eliminada y ya no se puede modificar.'
        using errcode = '42501';
    end if;

    if old.invalidada_en is not null then
      raise exception 'La orden fue invalidada y ya no se puede modificar.';
    end if;

    if public.soy_supervisor() or public.soy_admin() then
      if not public.no_cambia(to_jsonb(old), to_jsonb(new),
           array['id', 'planta_id', 'codigo', 'creado_por', 'created_at',
                 'eliminada_en', 'eliminada_por',
                 'invalidada_en', 'invalidada_por', 'motivo_invalidacion']) then
        raise exception 'No se puede cambiar la planta, el código, el autor, la eliminación ni la invalidación'
          using errcode = '42501';
      end if;
    elsif old.asignado_a_uid = auth.uid() then
      -- El técnico asignado solo avanza el trabajo
      if not public.solo_cambia(to_jsonb(old), to_jsonb(new),
           array['estado', 'ultima_actividad', 'total_reportes',
                 'total_alertas', 'portada_url'])
         or new.estado not in ('en_progreso', 'validando', 'critica') then
        raise exception 'El técnico solo puede avanzar el estado del trabajo'
          using errcode = '42501';
      end if;
    else
      raise exception 'Sin permiso para editar esta orden' using errcode = '42501';
    end if;
  end if;
  new.ultima_actividad := now();   -- como serverTimestamp()
  return new;
end $$;

-- Una orden nueva nunca nace invalidada (la app no manda esas columnas,
-- pero no se confía en ello)
create or replace function public.orden_nace_valida() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.invalidada_en := null;
    new.invalidada_por := null;
    new.motivo_invalidacion := null;
  end if;
  return new;
end $$;

drop trigger if exists trg_b_orden_nace_valida on public.ordenes;
create trigger trg_b_orden_nace_valida
  before insert on public.ordenes
  for each row execute function public.orden_nace_valida();

-- ─── Una orden invalidada no recibe reportes ────────────────────────
create or replace function public.no_reportar_invalidada() returns trigger
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from public.ordenes
              where id = new.orden_id and invalidada_en is not null) then
    raise exception 'La orden fue invalidada y ya no recibe reportes.';
  end if;
  return new;
end $$;

drop trigger if exists trg_a_no_reportar_invalidada on public.reportes;
create trigger trg_a_no_reportar_invalidada
  before insert on public.reportes
  for each row execute function public.no_reportar_invalidada();

-- ─── Los recordatorios ignoran las invalidadas ──────────────────────
-- Igual que en 07_recordatorios_estancadas.sql, más una condición.
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
     and o.invalidada_en is null
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

commit;

-- ────────────────────────────────────────────────────────────────────
-- COMPROBACIÓN (debe dar 4 filas con "sí")
-- ────────────────────────────────────────────────────────────────────
select 'columnas de invalidación en ordenes' as que,
       case when (select count(*) from information_schema.columns
                   where table_schema = 'public' and table_name = 'ordenes'
                     and column_name in ('invalidada_en', 'invalidada_por', 'motivo_invalidacion')) = 3
            then 'sí' else 'NO' end as listo
union all
select 'función invalidar_orden',
       case when exists (select 1 from pg_proc where proname = 'invalidar_orden')
            then 'sí' else 'NO' end
union all
select 'trigger: no reportar en invalidadas',
       case when exists (select 1 from pg_trigger where tgname = 'trg_a_no_reportar_invalidada')
            then 'sí' else 'NO' end
union all
select 'trigger: una orden nueva nace válida',
       case when exists (select 1 from pg_trigger where tgname = 'trg_b_orden_nace_valida')
            then 'sí' else 'NO' end;
