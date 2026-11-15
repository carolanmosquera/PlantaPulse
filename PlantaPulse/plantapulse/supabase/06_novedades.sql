-- Ejecutar después de esquema.sql y los scripts 02 a 05.
begin;

alter table public.novedades add column if not exists motivo_descarte text;

create index if not exists novedades_planta_fecha_idx
  on public.novedades (planta_id, created_at desc);

drop policy if exists "novedades alta" on public.novedades;
create policy "novedades alta" on public.novedades for insert to authenticated
  with check (
    (select public.estoy_activo())
    and planta_id = (select public.mi_planta())
    and autor ->> 'uid' = (select auth.uid())::text
    and estado = 'reportada'
    and orden_id is null
    and revisada_por is null
    and revisada_en is null
    and motivo_descarte is null
    and length(regexp_replace(descripcion, '^[[:space:]]+|[[:space:]]+$', '', 'g'))
      between 5 and 500
    and categoria in ('electrica', 'mecanica', 'infraestructura', 'seguridad', 'limpieza', 'otra')
    and jsonb_typeof(evidencias) = 'array'
    and jsonb_array_length(evidencias) <= 4
  );

-- La revisión se hace mediante las funciones de abajo, que validan la
-- transición junto con los datos de la orden o del descarte.
drop policy if exists "novedades update supervisor" on public.novedades;
revoke update on public.novedades from anon, authenticated;

create or replace function public.convertir_novedad(p_novedad_id uuid, p_orden jsonb)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_novedad public.novedades%rowtype;
  v_orden_id uuid;
  v_equipo public.equipos%rowtype;
  v_tecnico public.usuarios%rowtype;
  v_revisor jsonb;
begin
  if not (public.soy_supervisor() or public.soy_admin()) then
    raise exception 'Solo un supervisor o un administrador puede convertir novedades.'
      using errcode = '42501';
  end if;

  select * into v_novedad
    from public.novedades
    where id = p_novedad_id and planta_id = public.mi_planta()
    for update;
  if not found then
    raise exception 'La novedad no está disponible en tu planta.'
      using errcode = '42501';
  end if;

  v_orden_id := (p_orden ->> 'id')::uuid;
  -- Permite confirmar un reintento de la misma publicación si la respuesta se perdió.
  if v_novedad.estado = 'convertida' and v_novedad.orden_id = v_orden_id then
    return v_orden_id;
  end if;
  if v_novedad.estado not in ('reportada', 'revisada') or v_novedad.orden_id is not null then
    raise exception 'Esta novedad ya fue resuelta.';
  end if;

  if v_orden_id is null or nullif(btrim(p_orden ->> 'codigo'), '') is null
     or coalesce(length(btrim(p_orden ->> 'titulo')), 0) < 5
     or coalesce(p_orden ->> 'prioridad', '') not in ('baja', 'media', 'alta', 'critica')
     or nullif(p_orden ->> 'fecha_limite', '') is null then
    raise exception 'Completa los datos de la orden.';
  end if;

  select * into v_equipo from public.equipos
    where id = (p_orden ->> 'equipo_id')::uuid
      and planta_id = v_novedad.planta_id and activo;
  if not found then
    raise exception 'Selecciona un equipo activo de tu planta.';
  end if;

  select * into v_tecnico from public.usuarios
    where id = (p_orden ->> 'asignado_a_uid')::uuid
      and planta_id = v_novedad.planta_id and rol = 'tecnico' and estado = 'activo';
  if not found then
    raise exception 'Selecciona un técnico activo de tu planta.';
  end if;

  select jsonb_build_object('uid', id, 'nombre', nombre, 'fotoUrl', foto_url)
    into v_revisor from public.usuarios where id = auth.uid();

  insert into public.ordenes (
    id, codigo, planta_id, titulo, descripcion, categoria, zona_id, zona_nombre,
    equipo_id, equipo_nombre, creado_por, asignado_a, asignado_a_uid, estado,
    prioridad, fecha_limite, portada_url, evidencias
  ) values (
    v_orden_id, p_orden ->> 'codigo', v_novedad.planta_id, btrim(p_orden ->> 'titulo'),
    coalesce(p_orden ->> 'descripcion', ''), coalesce(p_orden ->> 'categoria', ''),
    v_equipo.zona_id, v_equipo.zona_nombre, v_equipo.id, v_equipo.nombre, v_revisor,
    jsonb_build_object('uid', v_tecnico.id, 'nombre', v_tecnico.nombre, 'fotoUrl', v_tecnico.foto_url),
    v_tecnico.id, 'pendiente', p_orden ->> 'prioridad',
    (p_orden ->> 'fecha_limite')::timestamptz, p_orden ->> 'portada_url',
    coalesce(p_orden -> 'evidencias', '[]'::jsonb)
  );

  update public.novedades
    set estado = 'convertida', orden_id = v_orden_id, revisada_por = v_revisor,
        revisada_en = now(), motivo_descarte = null
    where id = v_novedad.id;
  return v_orden_id;
end $$;

create or replace function public.descartar_novedad(p_novedad_id uuid, p_motivo text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_novedad public.novedades%rowtype;
  v_revisor jsonb;
  v_motivo text := regexp_replace(p_motivo, '^[[:space:]]+|[[:space:]]+$', '', 'g');
begin
  if not (public.soy_supervisor() or public.soy_admin()) then
    raise exception 'Solo un supervisor o un administrador puede descartar novedades.'
      using errcode = '42501';
  end if;
  if coalesce(length(v_motivo), 0) not between 1 and 500 then
    raise exception 'Escribe un motivo de descarte de hasta 500 caracteres.';
  end if;

  select * into v_novedad
    from public.novedades
    where id = p_novedad_id and planta_id = public.mi_planta()
    for update;
  if not found then
    raise exception 'La novedad no está disponible en tu planta.'
      using errcode = '42501';
  end if;
  if v_novedad.estado = 'descartada' and v_novedad.motivo_descarte = v_motivo
     and v_novedad.revisada_por ->> 'uid' = auth.uid()::text then
    return;
  end if;
  if v_novedad.estado not in ('reportada', 'revisada') or v_novedad.orden_id is not null then
    raise exception 'Esta novedad ya fue resuelta.';
  end if;

  select jsonb_build_object('uid', id, 'nombre', nombre, 'fotoUrl', foto_url)
    into v_revisor from public.usuarios where id = auth.uid();

  update public.novedades
    set estado = 'descartada', motivo_descarte = v_motivo, revisada_por = v_revisor,
        revisada_en = now()
    where id = v_novedad.id;
end $$;

revoke execute on function public.convertir_novedad(uuid, jsonb) from public, anon;
revoke execute on function public.descartar_novedad(uuid, text) from public, anon;
grant execute on function public.convertir_novedad(uuid, jsonb) to authenticated;
grant execute on function public.descartar_novedad(uuid, text) to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'novedades'
  ) then
    alter publication supabase_realtime add table public.novedades;
  end if;
end $$;

commit;
