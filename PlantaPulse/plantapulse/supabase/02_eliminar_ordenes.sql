-- ═══════════════════════════════════════════════════════════════════
-- PlantaPulse — eliminar órdenes creadas por equivocación
-- Ejecutar UNA vez en el SQL Editor, después de esquema.sql y de los
-- scripts de catálogos.
--
-- Por qué NO es un DELETE:
--   · El historial de mantenimiento es evidencia: queda quién eliminó la
--     orden y cuándo, y nada puede quedar apuntando a una fila borrada
--     (reportes, alertas y novedades referencian ordenes.id).
--   · Un DELETE rechazado por RLS no da error: simplemente no borra nada,
--     y la app diría "eliminada" sin haberlo hecho.
--   · Realtime no filtra bien los DELETE: otros teléfonos podrían seguir
--     viendo la orden. Un UPDATE llega a todos por el stream normal.
--
-- Qué se puede eliminar: solo una orden "virgen" — pendiente, sin
-- reportes, sin alertas y sin novedades vinculadas. Si ya hubo trabajo,
-- lo correcto es cerrarla, no hacerla desaparecer.
--
-- OJO: este script REEMPLAZA proteger_ordenes() y la política
-- "reportes alta". Si tus scripts de catálogos también las modificaron,
-- compara antes de ejecutar.
-- ═══════════════════════════════════════════════════════════════════

-- ─── COLUMNAS ──────────────────────────────────────────────────────

alter table ordenes add column if not exists eliminada_en timestamptz;
alter table ordenes add column if not exists eliminada_por jsonb;  -- UsuarioRef

-- El feed y Mis Tareas solo leen las vigentes
create index if not exists ordenes_vigentes
  on ordenes (planta_id, created_at desc) where eliminada_en is null;


-- ─── FUNCIÓN: eliminar_orden ───────────────────────────────────────
-- SECURITY DEFINER: la app no tiene permiso para tocar eliminada_en
-- directamente (ver el trigger de abajo); solo puede hacerlo a través
-- de esta función, que valida todo antes.
--
-- Errores (la app muestra el mensaje tal cual):
--   42501 → no es supervisor ni admin
--   P0002 → la orden no existe o es de otra planta
--   P0001 → no se puede eliminar (ya empezó, tiene reportes, etc.)

create or replace function public.eliminar_orden(p_orden_id uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  o public.ordenes%rowtype;
  autor jsonb;
begin
  if not (public.soy_supervisor() or public.soy_admin()) then
    raise exception 'Solo un supervisor o un administrador puede eliminar órdenes.'
      using errcode = '42501';
  end if;

  -- FOR UPDATE: bloquea la fila. Un reporte que se esté insertando en
  -- este momento (su llave foránea toma un bloqueo sobre la orden) espera
  -- o hace esperar, así la comprobación de abajo no se queda vieja.
  select * into o from public.ordenes where id = p_orden_id for update;

  if not found or o.planta_id is distinct from public.mi_planta() then
    raise exception 'La orden no existe.' using errcode = 'P0002';
  end if;

  -- Idempotente: pulsar dos veces no es un error
  if o.eliminada_en is not null then
    return;
  end if;

  if o.estado <> 'pendiente' then
    raise exception 'Solo se puede eliminar una orden pendiente. Esta ya tiene trabajo en curso: ciérrala en lugar de eliminarla.'
      using errcode = 'P0001';
  end if;

  if exists (select 1 from public.reportes where orden_id = p_orden_id) then
    raise exception 'La orden tiene reportes de avance y no se puede eliminar.'
      using errcode = 'P0001';
  end if;

  if exists (select 1 from public.alertas where orden_id = p_orden_id) then
    raise exception 'La orden tiene alertas vinculadas y no se puede eliminar.'
      using errcode = 'P0001';
  end if;

  if exists (select 1 from public.novedades where orden_id = p_orden_id) then
    raise exception 'La orden salió de una novedad y no se puede eliminar.'
      using errcode = 'P0001';
  end if;

  select jsonb_build_object('uid', u.id, 'nombre', u.nombre, 'fotoUrl', u.foto_url)
    into autor
    from public.usuarios u where u.id = auth.uid();

  update public.ordenes
     set eliminada_en = now(),
         eliminada_por = autor
   where id = p_orden_id;
end $$;

revoke all on function public.eliminar_orden(uuid) from public, anon;
grant execute on function public.eliminar_orden(uuid) to authenticated;


-- ─── TRIGGER: proteger_ordenes (reemplazo) ─────────────────────────
-- Cambios respecto a esquema.sql:
--   1. El admin edita igual que el supervisor (antes solo soy_supervisor(),
--      y al admin le fallaban "Editar orden" y "Asignar técnico").
--   2. Nadie puede tocar eliminada_en / eliminada_por con un update
--      directo: solo eliminar_orden(), que corre como dueño de la tabla y
--      por eso no entra en esta validación.
--   3. Una orden eliminada ya no se puede modificar.

create or replace function public.proteger_ordenes() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon') then
    if old.eliminada_en is not null then
      raise exception 'La orden fue eliminada y ya no se puede modificar.'
        using errcode = '42501';
    end if;

    if public.soy_supervisor() or public.soy_admin() then
      if not public.no_cambia(to_jsonb(old), to_jsonb(new),
           array['id', 'planta_id', 'codigo', 'creado_por', 'created_at',
                 'eliminada_en', 'eliminada_por']) then
        raise exception 'No se puede cambiar la planta, el código, el autor ni la eliminación'
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


-- ─── RLS: no se reporta sobre una orden eliminada ──────────────────
-- La lectura NO se cambia a propósito: si RLS ocultara las eliminadas,
-- el evento de tiempo real de la eliminación no llegaría a nadie y la
-- orden seguiría en las pantallas abiertas. La app las filtra al leer.

drop policy if exists "reportes alta" on reportes;
create policy "reportes alta" on reportes for insert
  with check (
    (select public.estoy_activo())
    and autor ->> 'uid' = (select auth.uid())::text
    and exists (
      select 1 from ordenes o
      where o.id = reportes.orden_id
        and o.eliminada_en is null
        and (o.asignado_a_uid = (select auth.uid())
             or (select public.soy_supervisor())
             or (select public.soy_admin()))
    )
    and jsonb_typeof(evidencias) = 'array'
    and jsonb_array_length(evidencias) <= 4
  );
