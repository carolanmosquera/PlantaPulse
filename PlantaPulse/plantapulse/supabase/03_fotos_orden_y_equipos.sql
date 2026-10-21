-- ═══════════════════════════════════════════════════════════════════
-- PlantaPulse — fotos al crear la orden, portada con la última foto,
-- y edición / baja de equipos.
-- Ejecutar UNA vez en el SQL Editor, después de 02_eliminar_ordenes.sql.
--
-- OJO: reemplaza proteger_equipos() y la política de UPDATE de equipos.
-- Si tus scripts de catálogos las modificaron, compara antes de ejecutar.
-- ═══════════════════════════════════════════════════════════════════


-- ─── 1. FOTOS DEL HALLAZGO EN LA ORDEN ─────────────────────────────
-- Las fotos que el supervisor toma al CREAR la orden (paso 2 del
-- asistente). Mismo formato que reportes.evidencias:
--   [{"ruta": "planta/orden/uuid.jpg", "subidaEn": "...Z", "autorUid": "..."}]
-- Se guarda la RUTA, nunca la URL.
--
-- La app sube las fotos ANTES de insertar la orden (genera el id de la
-- orden ella misma), así que la orden nace ya con sus fotos: si una
-- subida falla, la orden no se crea.

alter table ordenes add column if not exists evidencias jsonb not null default '[]';

alter table ordenes drop constraint if exists ordenes_max_4_evidencias;
alter table ordenes add constraint ordenes_max_4_evidencias
  check (jsonb_typeof(evidencias) = 'array' and jsonb_array_length(evidencias) <= 4);


-- ─── 2. PORTADA = LA ÚLTIMA FOTO SUBIDA ────────────────────────────
-- al_publicar_reporte solo fija portada_url si la orden no tenía. Este
-- trigger corre DESPUÉS (los triggers del mismo momento van en orden
-- alfabético: 'zz_' queda al final) y la reemplaza por la última foto
-- del reporte recién publicado. Un reporte sin fotos no la toca: se
-- queda la última que se subió.
--
-- SECURITY DEFINER: corre como dueño de la tabla, así que proteger_ordenes
-- no lo frena aunque el reporte lo publique un técnico.

create or replace function public.portada_ultima_foto() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  ultima text;
begin
  if jsonb_typeof(new.evidencias) = 'array' and jsonb_array_length(new.evidencias) > 0 then
    ultima := new.evidencias -> -1 ->> 'ruta';
    if ultima is not null and ultima <> '' then
      update public.ordenes set portada_url = ultima where id = new.orden_id;
    end if;
  end if;
  return new;
end $$;

drop trigger if exists zz_portada_ultima_foto on reportes;
create trigger zz_portada_ultima_foto after insert on reportes
  for each row execute function public.portada_ultima_foto();


-- ─── 3. EDITAR Y DAR DE BAJA EQUIPOS ───────────────────────────────
-- "Eliminar" un equipo es darlo de baja (activo = false), no borrarlo:
-- las órdenes viejas lo referencian (ordenes.equipo_id) y su historial
-- de mantenimiento tiene que seguir apuntando a algo. Un equipo de baja
-- deja de aparecer en el asistente.
--
-- Supervisor o admin cambian sus datos; nadie cambia su id ni su planta.

create or replace function public.proteger_equipos() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon') then
    if not (public.soy_supervisor() or public.soy_admin()) then
      raise exception 'Solo un supervisor o un administrador puede editar equipos'
        using errcode = '42501';
    end if;
    if not public.no_cambia(to_jsonb(old), to_jsonb(new), array['id', 'planta_id']) then
      raise exception 'Un equipo no se puede mover a otra planta'
        using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

-- zona_nombre sigue a zona_id también al editar (el trigger de los
-- catálogos lo pone al insertar). La zona tiene que ser de la misma planta.
create or replace function public.equipo_zona_al_editar() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  nombre_zona text;
begin
  if new.zona_id is distinct from old.zona_id then
    select z.nombre into nombre_zona
      from public.zonas z
     where z.id = new.zona_id and z.planta_id = new.planta_id;
    if nombre_zona is null then
      raise exception 'La zona no existe en esta planta' using errcode = 'P0001';
    end if;
    new.zona_nombre := nombre_zona;
  end if;
  return new;
end $$;

-- 'trg_b_' corre después de 'trg_a_proteger' (orden alfabético)
drop trigger if exists trg_b_equipo_zona on equipos;
create trigger trg_b_equipo_zona before update on equipos
  for each row execute function public.equipo_zona_al_editar();

-- La política de update pasa de "solo supervisor" a supervisor o admin
drop policy if exists "equipos update supervisor" on equipos;
drop policy if exists "equipos update operar" on equipos;
create policy "equipos update operar" on equipos for update
  using (
    ((select public.soy_supervisor()) or (select public.soy_admin()))
    and planta_id = (select public.mi_planta())
  )
  with check (planta_id = (select public.mi_planta()));
