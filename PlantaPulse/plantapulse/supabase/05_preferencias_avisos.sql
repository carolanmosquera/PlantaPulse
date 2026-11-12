-- ════════════════════════════════════════════════════════════════════
-- PlantaPulse — preferencias de avisos del usuario (KAN-100)
-- Ejecutar ENTERO en el SQL Editor. Idempotente.
-- ════════════════════════════════════════════════════════════════════
--
-- Ajustes > Notificaciones guarda aquí qué avisos quiere recibir cada
-- usuario, para que la elección sobreviva al cierre de la app.
--
--   {"push": true, "mantenimiento": true, "soloCriticas": false}
--
--   push           apagado = la app borra el fcm_token del perfil.
--   mantenimiento  avisos de estado de órdenes.
--   soloCriticas   solo avisos de prioridad alta/urgente.
--
-- QUIEN ENVÍA NOTIFICACIONES (KAN-97, KAN-95) DEBE LEER ESTA COLUMNA
-- antes de enviar y saltarse a quien tenga desactivado ese tipo de aviso.

alter table usuarios
  add column if not exists preferencias_avisos jsonb not null
  default '{"push": true, "mantenimiento": true, "soloCriticas": false}'::jsonb;

-- Solo un objeto con las tres claves booleanas: nadie guarda basura.
alter table usuarios drop constraint if exists preferencias_avisos_valida;
alter table usuarios add constraint preferencias_avisos_valida check (
  jsonb_typeof(preferencias_avisos) = 'object'
  and jsonb_typeof(preferencias_avisos -> 'push') = 'boolean'
  and jsonb_typeof(preferencias_avisos -> 'mantenimiento') = 'boolean'
  and jsonb_typeof(preferencias_avisos -> 'soloCriticas') = 'boolean'
);

-- El usuario puede editar sus propias preferencias: se agrega la columna
-- a la lista de datos personales del trigger (el resto no cambia).
create or replace function public.proteger_usuarios() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;

  if public.soy_admin() and old.id <> auth.uid() and old.estado = 'pendiente' then
    -- Aprobación o rechazo: solo la decisión y la firma
    if not public.solo_cambia(to_jsonb(old), to_jsonb(new),
         array['estado', 'rol', 'planta_id', 'aprobado_por', 'aprobado_en']) then
      raise exception 'Al aprobar solo se cambian estado, rol, planta y firma'
        using errcode = '42501';
    end if;
  elsif old.id = auth.uid() then
    -- Datos personales: rol, estado y planta quedan bloqueados
    if not public.solo_cambia(to_jsonb(old), to_jsonb(new),
         array['nombre', 'foto_url', 'turno', 'fcm_token', 'especialidad',
               'preferencias_avisos']) then
      raise exception 'Solo puedes editar tus datos personales'
        using errcode = '42501';
    end if;
  else
    raise exception 'Sin permiso para editar este perfil' using errcode = '42501';
  end if;
  return new;
end $$;
