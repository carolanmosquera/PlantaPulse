-- ════════════════════════════════════════════════════════════════════
-- PlantaPulse — bandeja personal de avisos
-- Ejecutar después de esquema.sql y 05_preferencias_avisos.sql.
-- Idempotente.
-- ════════════════════════════════════════════════════════════════════

create table if not exists public.notificaciones (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  tipo text not null check (tipo in ('critica', 'preventiva', 'completada', 'info')),
  titulo text not null,
  descripcion text not null default '',
  codigo text,
  orden_id uuid references public.ordenes(id) on delete set null,
  alerta_id uuid references public.alertas(id) on delete set null,
  leida boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notificaciones_usuario_fecha
  on public.notificaciones (usuario_id, created_at desc);

alter table public.notificaciones enable row level security;

drop policy if exists "notificaciones lectura propia" on public.notificaciones;
create policy "notificaciones lectura propia" on public.notificaciones for select
  using ((select public.estoy_activo()) and usuario_id = (select auth.uid()));

drop policy if exists "notificaciones update propia" on public.notificaciones;
create policy "notificaciones update propia" on public.notificaciones for update
  using ((select public.estoy_activo()) and usuario_id = (select auth.uid()))
  with check ((select public.estoy_activo()) and usuario_id = (select auth.uid()));

revoke all on public.notificaciones from public, anon, authenticated;
grant select on public.notificaciones to authenticated;
grant update (leida) on public.notificaciones to authenticated;

create or replace function public.notificar_asignacion_orden()
returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  receptor public.usuarios%rowtype;
begin
  if tg_op = 'UPDATE' then
    if new.asignado_a_uid is not distinct from old.asignado_a_uid then
      return new;
    end if;
  end if;
  if new.asignado_a_uid is null then
    return new;
  end if;

  select * into receptor
    from public.usuarios
   where id = new.asignado_a_uid
     and planta_id = new.planta_id
     and rol = 'tecnico'
     and estado = 'activo'
     and activo;
  if not found
     or not coalesce((receptor.preferencias_avisos ->> 'mantenimiento')::boolean, true)
     or (
       coalesce((receptor.preferencias_avisos ->> 'soloCriticas')::boolean, false)
       and new.prioridad not in ('alta', 'critica')
     ) then
    return new;
  end if;

  insert into public.notificaciones
    (usuario_id, tipo, titulo, descripcion, codigo, orden_id)
  values
    (receptor.id, 'preventiva', 'Nueva orden asignada',
     'Se te asignó: ' || new.titulo, new.codigo, new.id);
  return new;
end $$;

revoke all on function public.notificar_asignacion_orden()
  from public, anon, authenticated;

drop trigger if exists trg_notificar_asignacion_orden_insert on public.ordenes;
create trigger trg_notificar_asignacion_orden_insert
  after insert on public.ordenes
  for each row execute function public.notificar_asignacion_orden();

drop trigger if exists trg_notificar_asignacion_orden_update on public.ordenes;
create trigger trg_notificar_asignacion_orden_update
  after update of asignado_a_uid on public.ordenes
  for each row execute function public.notificar_asignacion_orden();

create or replace function public.notificar_alerta_critica()
returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.estado <> 'abierta' then
    return new;
  end if;

  insert into public.notificaciones
    (usuario_id, tipo, titulo, descripcion, codigo, orden_id, alerta_id)
  select
    u.id,
    'critica',
    'Alerta crítica: ' || new.tipo,
    case
      when nullif(new.zona_nombre, '') is null then new.descripcion
      else new.zona_nombre || ': ' || new.descripcion
    end,
    o.codigo,
    new.orden_id,
    new.id
  from public.usuarios u
  left join public.ordenes o on o.id = new.orden_id
  where u.planta_id = new.planta_id
    and u.rol in ('supervisor', 'admin')
    and u.estado = 'activo'
    and u.activo
    and u.id is distinct from (new.creado_por ->> 'uid')::uuid;
  return new;
end $$;

revoke all on function public.notificar_alerta_critica()
  from public, anon, authenticated;

drop trigger if exists trg_notificar_alerta_critica on public.alertas;
create trigger trg_notificar_alerta_critica
  after insert on public.alertas
  for each row execute function public.notificar_alerta_critica();

do $$
begin
  if not exists (
    select 1
      from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'notificaciones'
  ) then
    alter publication supabase_realtime add table public.notificaciones;
  end if;
end $$;
