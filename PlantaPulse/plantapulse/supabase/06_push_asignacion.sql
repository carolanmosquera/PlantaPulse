-- ════════════════════════════════════════════════════════════════════
-- PlantaPulse — notificación push al asignar una orden (KAN-97)
-- Ejecutar ENTERO en el SQL Editor. Idempotente.
-- ════════════════════════════════════════════════════════════════════
--
-- Cuando una orden nace con responsable, o se le cambia el responsable,
-- la base llama a la Edge Function 'enviar-push', que le manda la
-- notificación al teléfono del técnico (supabase/functions/enviar-push).
--
-- ANTES de ejecutar este archivo, una sola vez, guardar en el Vault el
-- secreto compartido con la función (el MISMO valor que el secreto
-- PUSH_WEBHOOK_SECRET de la función; nunca se escribe en este archivo):
--
--   select vault.create_secret('<un valor largo y aleatorio>', 'push_webhook_secret');
--
-- Sin ese secreto el trigger no hace nada: las órdenes se siguen creando
-- y asignando normal, solo que sin notificación.

-- pg_net hace la llamada HTTP sin esperar la respuesta: asignar una
-- orden nunca se vuelve lento ni falla porque Firebase esté caído.
create extension if not exists pg_net with schema extensions;

create or replace function public.avisar_asignacion() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  secreto text;
begin
  if new.asignado_a_uid is null or new.eliminada_en is not null then
    return new;
  end if;
  -- En un update, solo si cambió el responsable
  if tg_op = 'UPDATE' and new.asignado_a_uid is not distinct from old.asignado_a_uid then
    return new;
  end if;

  select decrypted_secret into secreto
    from vault.decrypted_secrets
   where name = 'push_webhook_secret';
  if secreto is null then
    return new;
  end if;

  perform net.http_post(
    url     := 'https://uxajglpaoofragjxcrvx.supabase.co/functions/v1/enviar-push',
    body    := jsonb_build_object('tipo', 'asignacion', 'orden_id', new.id),
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-webhook-secret', secreto)
  );
  return new;
end $$;

-- AFTER: la orden ya quedó guardada cuando se avisa. El nombre empieza
-- por z para correr después de los triggers que protegen la tabla.
drop trigger if exists trg_z_avisar_asignacion on ordenes;
create trigger trg_z_avisar_asignacion
  after insert or update of asignado_a_uid on ordenes
  for each row execute function public.avisar_asignacion();

-- Nadie la llama a mano desde la app
revoke execute on function public.avisar_asignacion() from public, anon, authenticated;
