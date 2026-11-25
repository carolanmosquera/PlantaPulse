-- ════════════════════════════════════════════════════════════════════
-- PlantaPulse — marcar una alerta crítica como solucionada
-- Ejecutar después de esquema.sql y de 06_notificaciones_usuario.sql.
-- Idempotente: se puede correr más de una vez. Va en una transacción:
-- si algo falla, no se aplica nada.
-- ════════════════════════════════════════════════════════════════════
--
-- Qué hace:
--   1. Guarda quién solucionó la alerta, cuándo y una nota opcional
--      (la alerta no se borra: queda como historial).
--   2. resolver_alerta(): solo un supervisor o un admin de la planta la
--      cierra. Valida todo en el servidor.
--   3. Los avisos de esa alerta en la bandeja de cada usuario se ARCHIVAN
--      (no se borran): el tiempo real de Supabase entrega los cambios de
--      fila a cada usuario, pero no garantiza los borrados en una lista
--      filtrada por usuario.
--   4. La app ya no actualiza la tabla alertas directamente: todo pasa
--      por la función (antes la política dejaba cambiar el estado sin
--      registrar quién lo hizo, y el admin no podía).

begin;

-- ─── Historial de la resolución ─────────────────────────────────────
alter table public.alertas add column if not exists resuelta_por jsonb;
alter table public.alertas add column if not exists resuelta_en timestamptz;
alter table public.alertas add column if not exists nota_resolucion text;

-- ─── Avisos archivados ──────────────────────────────────────────────
-- Un aviso archivado ya no se muestra en la bandeja. Solo lo pone el
-- servidor: la app sigue pudiendo cambiar únicamente 'leida'.
alter table public.notificaciones
  add column if not exists archivada boolean not null default false;

-- ─── La resolución ──────────────────────────────────────────────────
create or replace function public.resolver_alerta(
  p_alerta_id uuid,
  p_nota text default ''
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_alerta public.alertas%rowtype;
  v_nota text := regexp_replace(coalesce(p_nota, ''),
                                '^[[:space:]]+|[[:space:]]+$', '', 'g');
  v_quien jsonb;
begin
  if not (public.soy_supervisor() or public.soy_admin()) then
    raise exception 'Solo un supervisor o un administrador puede dar por solucionada una alerta.'
      using errcode = '42501';
  end if;
  if length(v_nota) > 300 then
    raise exception 'La nota de cierre admite hasta 300 caracteres.';
  end if;

  select * into v_alerta
    from public.alertas
   where id = p_alerta_id and planta_id = public.mi_planta()
     for update;
  if not found then
    raise exception 'La alerta no está disponible en tu planta.'
      using errcode = '42501';
  end if;

  -- Ya la cerró otra persona (o es un reintento): no es un error, y la
  -- firma de quien la cerró primero se conserva
  if v_alerta.estado = 'cerrada' then
    return;
  end if;

  select jsonb_build_object('uid', id, 'nombre', nombre, 'fotoUrl', foto_url)
    into v_quien
    from public.usuarios
   where id = auth.uid();

  update public.alertas
     set estado = 'cerrada',
         resuelta_por = v_quien,
         resuelta_en = now(),
         nota_resolucion = nullif(v_nota, '')
   where id = v_alerta.id;

  -- Limpia la bandeja de todos: los avisos de esta alerta dejan de verse
  update public.notificaciones
     set archivada = true,
         leida = true
   where alerta_id = v_alerta.id
     and not archivada;
end $$;

revoke execute on function public.resolver_alerta(uuid, text) from public, anon;
grant execute on function public.resolver_alerta(uuid, text) to authenticated;

-- ─── La app ya no edita alertas directamente ────────────────────────
-- La app de este sprint no usa ese permiso: cerrar una alerta pasa por
-- resolver_alerta(), que deja la firma.
drop policy if exists "alertas update supervisor" on public.alertas;
revoke update on public.alertas from anon, authenticated;

commit;

-- ────────────────────────────────────────────────────────────────────
-- COMPROBACIÓN (debe dar 3 filas con "sí")
-- ────────────────────────────────────────────────────────────────────
select 'columnas de resolución en alertas' as que,
       case when (select count(*) from information_schema.columns
                   where table_schema = 'public' and table_name = 'alertas'
                     and column_name in ('resuelta_por', 'resuelta_en', 'nota_resolucion')) = 3
            then 'sí' else 'NO' end as listo
union all
select 'columna notificaciones.archivada',
       case when exists (select 1 from information_schema.columns
                          where table_schema = 'public' and table_name = 'notificaciones'
                            and column_name = 'archivada')
            then 'sí' else 'NO' end
union all
select 'función resolver_alerta',
       case when exists (select 1 from pg_proc where proname = 'resolver_alerta')
            then 'sí' else 'NO' end;
