-- ═══════════════════════════════════════════════════════════════════
-- PlantaPulse — esquema de Supabase (Postgres + RLS)
-- Proyecto: uxajglpaoofragjxcrvx
--
-- Traducción de firestore.rules. Cómo usarlo:
--   1. Authentication → Providers → Email → desactivar "Confirm email".
--   2. Pegar este archivo COMPLETO en el SQL Editor y ejecutarlo
--      sobre un proyecto vacío (una sola vez).
--   3. Authentication → Add user (correo y contraseña del admin),
--      copiar su UUID y ejecutar el bloque "ADMIN" del final.
--
-- Convención: columnas en snake_case. Los modelos de datos de la app
-- traducen a las propiedades camelCase de las entidades.
--
-- Diferencia clave con Firestore: aquí RLS FILTRA en silencio. Una
-- consulta sin permiso no falla: devuelve menos filas. Si una lista
-- sale vacía y esperabas datos, sospecha primero de una política.
-- ═══════════════════════════════════════════════════════════════════

-- Para volver a empezar desde cero (borra TODO lo de este archivo):
-- drop table if exists alertas, novedades, reportes, ordenes, usuarios,
--   equipos, zonas, plantas cascade;
-- drop function if exists mi_estado, mi_rol, mi_planta, estoy_activo,
--   soy_admin, soy_supervisor, solo_cambia, no_cambia, sellar_creacion,
--   sellar_orden_nueva, sellar_aprobacion, proteger_usuarios,
--   proteger_ordenes, proteger_equipos, proteger_novedades,
--   proteger_alertas cascade;


-- ─── TABLAS ────────────────────────────────────────────────────────

create table plantas (
  id text primary key,
  nombre text not null,
  ubicacion text default '',
  activo boolean default true
);

create table zonas (
  id text primary key,
  planta_id text references plantas(id) on delete cascade,
  nombre text not null,
  codigo text default '',
  descripcion text default ''
);

create table equipos (
  id uuid primary key default gen_random_uuid(),
  planta_id text references plantas(id) on delete cascade,
  zona_id text references zonas(id),
  zona_nombre text default '',
  nombre text not null,
  serial text default '',
  modelo text default '',
  tipo text default '',
  foto_url text,
  estado text default 'operativo',
  ultimo_mantenimiento timestamptz,
  activo boolean default true
);

-- El id ES el de auth.users: un perfil por cuenta.
-- La contraseña NO está aquí: vive solo (como hash) en auth.users.
create table usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  email text not null,
  rol text not null default 'tecnico',
  estado text not null default 'pendiente',
  especialidad text default '',
  planta_id text default '',          -- '' hasta que el admin la asigne
  zonas_asignadas text[] default '{}',
  foto_url text,
  turno text default '',
  fcm_token text,
  activo boolean default true,
  aprobado_por jsonb,                 -- UsuarioRef: {uid, nombre, fotoUrl}
  aprobado_en timestamptz,            -- lo pone el trigger, nunca la app
  created_at timestamptz default now()
);

create table ordenes (
  id uuid primary key default gen_random_uuid(),
  codigo text not null,
  planta_id text not null references plantas(id),
  titulo text not null,
  descripcion text default '',
  categoria text default 'mecanico',
  zona_id text default '',
  zona_nombre text default '',
  equipo_id uuid references equipos(id),
  equipo_nombre text,
  creado_por jsonb not null,          -- UsuarioRef denormalizado
  asignado_a jsonb not null,          -- UsuarioRef denormalizado
  asignado_a_uid uuid not null references usuarios(id),  -- copia plana para filtrar
  estado text not null default 'pendiente',
  prioridad text not null default 'media',
  created_at timestamptz default now(),
  fecha_limite timestamptz not null,
  fecha_cierre timestamptz,
  ultima_actividad timestamptz default now(),
  portada_url text,
  total_reportes int default 0,
  total_alertas int default 0,
  generada_por_ia boolean default false,
  nota_original text,
  validada_por jsonb,
  observaciones_supervisor text
);

-- En Firestore era la subcolección ordenes/{id}/reportes.
create table reportes (
  id uuid primary key default gen_random_uuid(),
  orden_id uuid not null references ordenes(id) on delete cascade,
  autor jsonb not null,
  detalles text default '',
  estado_trabajo text default 'en_progreso',
  evidencias jsonb default '[]',      -- máximo 4 (ver política)
  es_alerta_critica boolean default false,
  generado_por_ia boolean default false,
  created_at timestamptz default now()
);

create table novedades (
  id uuid primary key default gen_random_uuid(),
  planta_id text not null references plantas(id),
  zona_id text default '',
  zona_nombre text default '',
  descripcion text not null,
  categoria text default 'otra',
  autor jsonb not null,
  evidencias jsonb default '[]',
  estado text not null default 'reportada',
  orden_id uuid references ordenes(id),
  revisada_por jsonb,
  revisada_en timestamptz,
  created_at timestamptz default now()
);

create table alertas (
  id uuid primary key default gen_random_uuid(),
  planta_id text not null references plantas(id),
  zona_id text default '',
  zona_nombre text default '',
  orden_id uuid references ordenes(id),
  tipo text not null,
  descripcion text not null,
  creado_por jsonb not null,
  ubicacion_gps jsonb,                -- PuntoGps: {"latitude": .., "longitude": ..}
  evidencias jsonb default '[]',
  estado text not null default 'abierta',
  created_at timestamptz default now()
);


-- ─── ÍNDICES ───────────────────────────────────────────────────────
-- Reemplazan a los índices compuestos de Firestore.

create index on ordenes (planta_id, created_at desc);
create index on ordenes (planta_id, asignado_a_uid, fecha_limite);
create index on ordenes (planta_id, estado, created_at desc);
create index on equipos (planta_id, activo, nombre);
create index on usuarios (estado);
create index on reportes (orden_id, created_at);

-- Búsqueda de texto en el historial: lo que Firestore no podía hacer.
create index ordenes_busqueda on ordenes
  using gin (to_tsvector('spanish',
    coalesce(titulo, '') || ' ' || coalesce(descripcion, '')));


-- ─── FUNCIONES AUXILIARES DE PERMISOS ──────────────────────────────
-- Las políticas sobre 'usuarios' necesitan consultar 'usuarios' para
-- saber el rol. Sin SECURITY DEFINER eso provoca recursión infinita en
-- RLS y la consulta falla. Es el error número uno al migrar.
--
-- search_path vacío + nombres calificados (public.usuarios): evita que
-- alguien cuele una tabla con el mismo nombre en otro esquema y la
-- función privilegiada la lea.

create or replace function public.mi_estado() returns text
language sql security definer stable set search_path = '' as $$
  select estado from public.usuarios where id = auth.uid()
$$;

create or replace function public.mi_rol() returns text
language sql security definer stable set search_path = '' as $$
  select rol from public.usuarios where id = auth.uid()
$$;

create or replace function public.mi_planta() returns text
language sql security definer stable set search_path = '' as $$
  select planta_id from public.usuarios where id = auth.uid()
$$;

create or replace function public.estoy_activo() returns boolean
language sql security definer stable set search_path = '' as $$
  select coalesce(public.mi_estado() = 'activo', false)
$$;

create or replace function public.soy_admin() returns boolean
language sql security definer stable set search_path = '' as $$
  select public.estoy_activo() and coalesce(public.mi_rol() = 'admin', false)
$$;

create or replace function public.soy_supervisor() returns boolean
language sql security definer stable set search_path = '' as $$
  select public.estoy_activo() and coalesce(public.mi_rol() = 'supervisor', false)
$$;

-- Equivalente a soloCambia([...]) de Firestore: fuera de 'permitidos',
-- la fila vieja y la nueva son idénticas.
create or replace function public.solo_cambia(
  viejo jsonb, nuevo jsonb, permitidos text[]
) returns boolean
language sql immutable set search_path = '' as $$
  select (viejo - permitidos) = (nuevo - permitidos)
$$;

-- Lo contrario: ninguna de las columnas 'protegidas' cambió.
create or replace function public.no_cambia(
  viejo jsonb, nuevo jsonb, protegidas text[]
) returns boolean
language sql immutable set search_path = '' as $$
  select not exists (
    select 1 from unnest(protegidas) as k
    where viejo -> k is distinct from nuevo -> k
  )
$$;


-- ─── TRIGGERS: SELLOS DE TIEMPO DEL SERVIDOR ───────────────────────
-- Sustituyen a FieldValue.serverTimestamp(): la fecha la pone el
-- servidor, no el reloj del teléfono (que puede estar mal configurado),
-- aunque la app mande otra.

create or replace function public.sellar_creacion() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.created_at := now();
  return new;
end $$;

create or replace function public.sellar_orden_nueva() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.created_at := now();
  new.ultima_actividad := now();
  return new;
end $$;

create trigger trg_sellar_creacion before insert on usuarios
  for each row execute function public.sellar_creacion();
create trigger trg_sellar_creacion before insert on ordenes
  for each row execute function public.sellar_orden_nueva();
create trigger trg_sellar_creacion before insert on reportes
  for each row execute function public.sellar_creacion();
create trigger trg_sellar_creacion before insert on novedades
  for each row execute function public.sellar_creacion();
create trigger trg_sellar_creacion before insert on alertas
  for each row execute function public.sellar_creacion();


-- ─── TRIGGERS: QUÉ COLUMNAS PUEDE CAMBIAR CADA QUIEN ───────────────
-- RLS decide QUÉ FILAS se pueden editar, pero solo ve la fila nueva:
-- no puede comparar con la vieja. El soloCambia([...]) de Firestore se
-- traduce, por eso, a triggers BEFORE UPDATE.
--
-- Los triggers del mismo momento se disparan en orden alfabético:
-- trg_a_* (validar) corre antes que trg_b_* (sellar).
--
-- Solo se aplican a peticiones de la app (rol 'authenticated' o 'anon').
-- El SQL Editor (postgres) y service_role quedan libres para mantenimiento.
-- El código 42501 llega a la app como error de permisos.

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
         array['nombre', 'foto_url', 'turno', 'fcm_token', 'especialidad']) then
      raise exception 'Solo puedes editar tus datos personales'
        using errcode = '42501';
    end if;
  else
    raise exception 'Sin permiso para editar este perfil' using errcode = '42501';
  end if;
  return new;
end $$;

-- Sustituye a la condición aprobadoEn == request.time de Firestore:
-- la fecha de aprobación la pone el servidor, y nadie puede falsearla.
create or replace function public.sellar_aprobacion() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.estado is distinct from old.estado then
    new.aprobado_en := now();
  else
    new.aprobado_en := old.aprobado_en;
  end if;
  return new;
end $$;

create trigger trg_a_proteger before update on usuarios
  for each row execute function public.proteger_usuarios();
create trigger trg_b_sellar_aprobacion before update on usuarios
  for each row execute function public.sellar_aprobacion();

create or replace function public.proteger_ordenes() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon') then
    if public.soy_supervisor() then
      -- El supervisor edita la orden, pero no su identidad ni su origen
      if not public.no_cambia(to_jsonb(old), to_jsonb(new),
           array['id', 'planta_id', 'codigo', 'creado_por', 'created_at']) then
        raise exception 'No se puede cambiar la planta, el código ni el autor'
          using errcode = '42501';
      end if;
    elsif old.asignado_a_uid = auth.uid() then
      -- El técnico asignado solo avanza el trabajo: no reasigna,
      -- no cambia prioridad ni cierra la orden.
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

create trigger trg_a_proteger before update on ordenes
  for each row execute function public.proteger_ordenes();

create or replace function public.proteger_equipos() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon')
     and not public.solo_cambia(to_jsonb(old), to_jsonb(new),
           array['estado', 'ultimo_mantenimiento']) then
    raise exception 'Del equipo solo se cambia estado y último mantenimiento'
      using errcode = '42501';
  end if;
  return new;
end $$;

create trigger trg_a_proteger before update on equipos
  for each row execute function public.proteger_equipos();

create or replace function public.proteger_novedades() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon')
     and not public.solo_cambia(to_jsonb(old), to_jsonb(new),
           array['estado', 'orden_id', 'revisada_por', 'revisada_en']) then
    raise exception 'De la novedad solo se cambia su revisión'
      using errcode = '42501';
  end if;
  return new;
end $$;

create trigger trg_a_proteger before update on novedades
  for each row execute function public.proteger_novedades();

create or replace function public.proteger_alertas() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon')
     and not public.solo_cambia(to_jsonb(old), to_jsonb(new), array['estado']) then
    raise exception 'De la alerta solo se cambia el estado'
      using errcode = '42501';
  end if;
  return new;
end $$;

create trigger trg_a_proteger before update on alertas
  for each row execute function public.proteger_alertas();


-- ─── RLS ───────────────────────────────────────────────────────────
-- Sin 'enable row level security' la tabla queda legible y escribible
-- para cualquiera con la clave publishable. TODAS lo llevan.
--
-- Sin política para una operación = prohibida. Por eso no hay ninguna
-- política de DELETE: el historial es evidencia, como en Firestore.
--
-- Las funciones van envueltas en (select ...): Postgres las evalúa una
-- vez por consulta en vez de una vez por fila.

alter table plantas   enable row level security;
alter table zonas     enable row level security;
alter table equipos   enable row level security;
alter table usuarios  enable row level security;
alter table ordenes   enable row level security;
alter table reportes  enable row level security;
alter table novedades enable row level security;
alter table alertas   enable row level security;

-- ─── PLANTAS: lectura pública ───
-- Solo son nombres de sedes: no es información sensible.
create policy "plantas lectura" on plantas for select
  using (true);

-- ─── ZONAS y EQUIPOS: solo cuentas activas ───
create policy "zonas lectura" on zonas for select
  using ((select public.estoy_activo()));

create policy "equipos lectura" on equipos for select
  using ((select public.estoy_activo()));

-- El supervisor actualiza estado y último mantenimiento al cerrar una
-- orden (las columnas las limita trg_a_proteger).
create policy "equipos update supervisor" on equipos for update
  using ((select public.soy_supervisor()) and planta_id = (select public.mi_planta()))
  with check (planta_id = (select public.mi_planta()));

-- ─── USUARIOS ───
-- Mi propio perfil siempre (la pantalla de espera lo necesita); los de
-- mi planta solo si estoy activo (un pendiente, con planta '', no ve a
-- los demás pendientes); el admin ve las solicitudes pendientes.
create policy "usuarios lectura" on usuarios for select
  using (
    id = (select auth.uid())
    or ((select public.estoy_activo()) and planta_id = (select public.mi_planta()))
    or ((select public.soy_admin()) and estado = 'pendiente')
  );

-- Registro: siempre técnico, pendiente, sin planta y sin aprobación.
create policy "usuarios alta" on usuarios for insert
  with check (
    id = (select auth.uid())
    and rol = 'tecnico'
    and estado = 'pendiente'
    and planta_id = ''
    and aprobado_por is null
    and aprobado_en is null
  );

-- Cada quien edita solo sus datos personales (columnas: ver trigger).
create policy "usuarios edicion propia" on usuarios for update
  using (id = (select auth.uid()))
  with check (
    id = (select auth.uid())
    and rol = (select public.mi_rol())
    and estado = (select public.mi_estado())
    and planta_id = (select public.mi_planta())
  );

-- El admin aprueba o rechaza solicitudes pendientes de OTROS.
-- No puede crear más admins, y queda firmado quién decidió.
--
-- OJO: soy_admin() va TAMBIÉN en el with check. Las políticas
-- permisivas se combinan con OR por separado: sin esto, un técnico
-- pendiente pasaría el 'using' de su edición propia y el 'with check'
-- de esta, y podría aprobarse a sí mismo como supervisor.
create policy "usuarios aprobacion admin" on usuarios for update
  using (
    (select public.soy_admin())
    and id <> (select auth.uid())
    and estado = 'pendiente'
  )
  with check (
    (select public.soy_admin())
    and id <> (select auth.uid())
    and estado in ('activo', 'rechazado')
    and rol in ('supervisor', 'tecnico')
    and aprobado_por ->> 'uid' = (select auth.uid())::text
    and (estado = 'rechazado' or length(planta_id) > 0)
  );

-- ─── ÓRDENES ───
create policy "ordenes lectura" on ordenes for select
  using ((select public.estoy_activo()) and planta_id = (select public.mi_planta()));

-- Solo el supervisor crea, siempre con responsable, y toda orden nace
-- pendiente: la prioridad crítica NO es un estado.
-- Se compara como texto: un uid mal formado no rompe la consulta.
create policy "ordenes alta supervisor" on ordenes for insert
  with check (
    (select public.soy_supervisor())
    and planta_id = (select public.mi_planta())
    and creado_por ->> 'uid' = (select auth.uid())::text
    and asignado_a_uid is not null
    and estado = 'pendiente'
  );

-- Supervisor o técnico asignado; qué columnas cambia cada uno lo
-- decide trg_a_proteger. El with check impide sacarla de la planta.
create policy "ordenes update" on ordenes for update
  using (
    (select public.estoy_activo())
    and planta_id = (select public.mi_planta())
    and ((select public.soy_supervisor()) or asignado_a_uid = (select auth.uid()))
  )
  with check (planta_id = (select public.mi_planta()));

-- ─── REPORTES ───
-- La subconsulta a 'ordenes' también pasa por RLS: solo ve órdenes de
-- mi planta, así que no hace falta repetir ese filtro.
create policy "reportes lectura" on reportes for select
  using (
    (select public.estoy_activo())
    and exists (select 1 from ordenes o where o.id = reportes.orden_id)
  );

create policy "reportes alta" on reportes for insert
  with check (
    (select public.estoy_activo())
    and autor ->> 'uid' = (select auth.uid())::text
    and exists (
      select 1 from ordenes o
      where o.id = reportes.orden_id
        and (o.asignado_a_uid = (select auth.uid()) or (select public.soy_supervisor()))
    )
    and jsonb_typeof(evidencias) = 'array'
    and jsonb_array_length(evidencias) <= 4
  );
-- Sin update ni delete: lo publicado no se edita.

-- ─── NOVEDADES ───
-- Cualquiera de la planta publica; todos ven; solo el supervisor decide.
create policy "novedades lectura" on novedades for select
  using ((select public.estoy_activo()) and planta_id = (select public.mi_planta()));

create policy "novedades alta" on novedades for insert
  with check (
    (select public.estoy_activo())
    and planta_id = (select public.mi_planta())
    and autor ->> 'uid' = (select auth.uid())::text
    and estado = 'reportada'
    and length(descripcion) between 5 and 500
    and jsonb_typeof(evidencias) = 'array'
    and jsonb_array_length(evidencias) <= 4
  );

create policy "novedades update supervisor" on novedades for update
  using ((select public.soy_supervisor()) and planta_id = (select public.mi_planta()))
  with check (planta_id = (select public.mi_planta()));

-- ─── ALERTAS CRÍTICAS ───
create policy "alertas lectura" on alertas for select
  using ((select public.estoy_activo()) and planta_id = (select public.mi_planta()));

create policy "alertas alta" on alertas for insert
  with check (
    (select public.estoy_activo())
    and planta_id = (select public.mi_planta())
    and creado_por ->> 'uid' = (select auth.uid())::text
    and estado = 'abierta'
    and jsonb_typeof(evidencias) = 'array'
    and jsonb_array_length(evidencias) <= 4
  );

create policy "alertas update supervisor" on alertas for update
  using ((select public.soy_supervisor()) and planta_id = (select public.mi_planta()))
  with check (planta_id = (select public.mi_planta()));


-- ─── PERMISOS DE LA API ────────────────────────────────────────────
-- RLS decide qué filas; estos GRANT deciden qué operaciones expone la
-- API. Se dan explícitos por si el proyecto no expone tablas nuevas
-- automáticamente. Ningún DELETE: tampoco hay políticas para borrar.

grant usage on schema public to anon, authenticated;
grant select on plantas to anon, authenticated;
grant select on zonas to authenticated;
grant select, update on equipos to authenticated;
grant select, insert, update on usuarios, ordenes, novedades, alertas to authenticated;
grant select, insert on reportes to authenticated;


-- ─── TIEMPO REAL ───────────────────────────────────────────────────
-- Sin esto, .stream() de la app solo recibe la carga inicial y nunca
-- se entera de los cambios: el feed no mostraría órdenes nuevas sin
-- recargar. Realtime respeta RLS: cada quien recibe solo lo que puede leer.
--   ordenes  → feed y "Mis Tareas"
--   usuarios → bandeja de solicitudes del admin y perfil propio

alter publication supabase_realtime add table ordenes, usuarios;


-- ─── DATOS SEMILLA ─────────────────────────────────────────────────

insert into plantas (id, nombre, ubicacion) values
  ('planta_norte', 'Planta Norte', 'Yumbo, Valle del Cauca');

insert into zonas (id, planta_id, nombre, codigo) values
  ('zona_ensamblaje_a', 'planta_norte', 'Línea de Ensamblaje A', 'ZN-01'),
  ('zona_compresores',  'planta_norte', 'Sala de Compresores',   'ZN-03');

insert into equipos (planta_id, zona_id, zona_nombre, nombre, serial, modelo, tipo)
values
  ('planta_norte', 'zona_compresores', 'Sala de Compresores',
   'Compresor Atlas Copco GA75', 'AC-88291-K', '2022', 'mecanico'),
  ('planta_norte', 'zona_ensamblaje_a', 'Línea de Ensamblaje A',
   'Bomba Centrífuga P-1', 'BC-44901', '2021', 'hidraulico');


-- ─── ADMIN ─────────────────────────────────────────────────────────
-- Va comentado a propósito: necesita que la cuenta exista ANTES en
-- auth.users (Authentication → Add user). Si se ejecutara junto con
-- todo lo anterior, '<UUID>' haría fallar el script entero.
--
-- Cuando tengas el UUID, quita los '--' de estas líneas, reemplaza
-- <UUID> y ejecuta SOLO este bloque:
--
-- insert into usuarios (id, nombre, email, rol, estado, planta_id)
-- values ('<UUID>', 'Administrador', 'admin@plantapulse.com',
--         'admin', 'activo', 'planta_norte');
