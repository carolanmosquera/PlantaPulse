-- Aplicar después de 02_eliminar_ordenes.sql en el SQL Editor de Supabase.
-- SECURITY INVOKER conserva las políticas RLS de ordenes.
create or replace function public.buscar_historial_ordenes(
  p_planta_id text,
  p_texto text default '',
  p_equipo_id uuid default null,
  p_desde integer default 0,
  p_limite integer default 30
) returns setof public.ordenes
language sql stable security invoker
set search_path = public
as $$
  select o.*
  from public.ordenes o
  where o.planta_id = p_planta_id
    and o.eliminada_en is null
    and (p_equipo_id is null or o.equipo_id = p_equipo_id)
    and (
      nullif(btrim(p_texto), '') is null
      or to_tsvector('spanish',
           coalesce(o.titulo, '') || ' ' || coalesce(o.descripcion, ''))
         @@ websearch_to_tsquery('spanish', p_texto)
    )
  order by o.created_at desc, o.id desc
  limit least(greatest(p_limite, 1), 100)
  offset greatest(p_desde, 0);
$$;

revoke all on function public.buscar_historial_ordenes(text,text,uuid,integer,integer)
  from public, anon;
grant execute on function public.buscar_historial_ordenes(text,text,uuid,integer,integer)
  to authenticated;
