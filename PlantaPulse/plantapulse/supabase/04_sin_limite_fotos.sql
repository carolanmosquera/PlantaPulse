-- ════════════════════════════════════════════════════════════════════
-- PlantaPulse — subir el tope de fotos por reporte y por orden
-- Ejecutar ENTERO en el SQL Editor. Idempotente.
-- ════════════════════════════════════════════════════════════════════
--
-- Cuatro fotos no alcanzan para una revisión técnica real: una falla
-- eléctrica puede necesitar la placa, el borne, el tablero, la etiqueta
-- del equipo y tres ángulos del montaje.
--
-- POR QUÉ QUEDA UN TOPE Y NO SE QUITA DEL TODO
--   La tabla 'reportes' no tiene política de UPDATE ni de DELETE: lo
--   publicado no se edita ni se borra, a propósito. Eso significa que
--   una fila mal formada es PERMANENTE. Si un reintento con error
--   duplicara el arreglo, o un bucle subiera mil entradas, ese reporte
--   quedaría para siempre y rompería la pantalla de detalle de esa
--   orden sin forma de arreglarlo desde la app.
--
--   30 está muy por encima de cualquier inspección real, así que en la
--   práctica no se nota, pero convierte un desastre permanente en un
--   mensaje de error. Si prefieres otro número, cámbialo en los dos
--   sitios de abajo.
--
--   Lo que NO se puede quitar es 'jsonb_typeof(evidencias) = array':
--   sin eso, un cliente podría mandar un objeto o un número en ese
--   campo y el modelo de Dart reventaría al leerlo.


-- ════ 1 · REPORTES ══════════════════════════════════════════════════
-- Se reescribe la política entera porque no se puede modificar un
-- trozo. Es la versión de 02_eliminar_ordenes.sql con el tope subido:
-- el resto de las condiciones queda idéntico.

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
    and jsonb_array_length(evidencias) <= 30
  );


-- ════ 2 · EVIDENCIA DEL HALLAZGO EN LA ORDEN ════════════════════════
-- El mismo criterio para las fotos que toma el supervisor al crear la
-- orden. Aquí es una restricción de tabla, no una política.

alter table ordenes drop constraint if exists ordenes_max_4_evidencias;
alter table ordenes drop constraint if exists ordenes_max_evidencias;
alter table ordenes add constraint ordenes_max_evidencias
  check (
    jsonb_typeof(evidencias) = 'array'
    and jsonb_array_length(evidencias) <= 30
  );


-- ════ 3 · LO QUE NO SE TOCA ═════════════════════════════════════════
-- 'novedades' y 'alertas' siguen con tope de 4, y es deliberado: una
-- novedad es una observación rápida de pasillo y una alerta es un aviso
-- urgente. Ninguna de las dos es una inspección documentada. Si quieres
-- subirlas también, son las políticas "novedades alta" y "alertas alta".


-- ════ COMPROBACIÓN ══════════════════════════════════════════════════
-- Debe decir 30 en las dos filas.
select 'reportes' as donde,
       substring(pg_get_expr(polwithcheck, polrelid) from 'jsonb_array_length\(evidencias\) <= \d+') as tope
from pg_policy where polname = 'reportes alta'
union all
select 'ordenes',
       substring(pg_get_constraintdef(oid) from 'jsonb_array_length\(evidencias\) <= \d+')
from pg_constraint where conname = 'ordenes_max_evidencias';
