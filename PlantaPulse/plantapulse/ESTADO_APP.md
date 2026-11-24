# Estado de PlantaPulse

*Actualizado: 5 de noviembre de 2026*

**En resumen:** lo central ya funciona con datos reales de Supabase: entrar y registrarse, crear órdenes, asignarlas, reportar avances con fotos y validarlas. Las 63 pruebas automáticas pasan. Lo que falta son las pantallas que vienen del diseño original y todavía muestran datos inventados: Perfil, Alertas, Emergencia y Resumen de turno.

---

## ✅ Lo que funciona

### Cuentas y acceso
- Inicio de sesión y pantalla de carga que recuerda la sesión abierta.
- Registro con rol y planta; la cuenta queda "en espera" hasta que la aprueben.
- El supervisor o admin aprueba o rechaza cuentas desde Perfil → "Solicitudes de registro".
- Tres roles con permisos distintos (técnico, supervisor, admin), también protegidos en la base de datos.

### Órdenes
- El feed se actualiza en vivo y muestra solo las órdenes de tu planta.
- Filtros: Todos, Pendiente, En Progreso, Urgente, Sin asignar y Por validar. También hay buscador por título, código o ubicación.
- Crear orden en 2 pasos: categoría, equipo, zona, prioridad, fecha límite y técnico (puede quedar sin asignar).
- Categorías y equipos se crean desde el mismo formulario. Los equipos se pueden ver, editar y eliminar, y "BUSCAR TODOS" los busca.
- En el detalle de la orden, el supervisor puede:
  - asignar técnico;
  - editar la orden, y desde ahí también reasignarla;
  - eliminarla, solo si sigue pendiente y no tiene reportes.

  El borrado no es definitivo: la orden se marca como eliminada y no quedan datos sueltos en la base.
- Accesos directos en el feed:
  - el técnico tiene "Mis tareas asignadas", con su conteo;
  - el supervisor tiene "Órdenes por validar", con su conteo.

### Reportes y validación
- El técnico llena reportes de avance con notas y hasta 30 fotos, de cámara o galería.
- Las fotos se suben a Storage, y la portada de la orden pasa a ser la última foto subida.
- Al publicar un reporte, la orden cambia de estado sola.
- El supervisor revisa la evidencia y aprueba, o devuelve la orden con una nota de qué corregir.

### Base técnica
- El código está separado en capas: la parte que habla con Supabase está aislada del resto, lo que permite probarlo todo sin red.
- Los scripts de Supabase están en [supabase/](supabase/), del `esquema.sql` al `04_sin_limite_fotos.sql`.

---

## ⏳ Lo que falta

| Pantalla | Estado actual |
|---|---|
| **Perfil** | Muestra datos fijos ("Ing. Carlos Mendoza", "142 órdenes", 98.2 %…) en vez del usuario conectado. Ya existe la lógica para editar el perfil, pero ninguna pantalla la usa todavía. "Historial de actividad" y "Certificaciones" no hacen nada. |
| **Alertas** (pestaña de abajo) | Lee una lista inventada (`datos_demo`). No hay conexión con Supabase para alertas ni novedades, y "Limpiar leídas" no hace nada. |
| **Emergencia** | La pantalla existe, pero ningún botón lleva a ella, y "Enviar" solo muestra un aviso: no guarda nada ni avisa a nadie. |
| **Resumen de turno** | Ningún botón lleva a ella; la fecha ("Hoy, 24 Mayo") y las cifras son fijas, y "Generar reporte" no hace nada. |
| **Ajustes** | Solo funciona "Cerrar sesión". Datos personales, contraseña, notificaciones y manuales no hacen nada, y la versión es un texto fijo. |
| **Notificaciones** | No hay avisos al teléfono cuando te asignan o te devuelven una orden. |

### Orden sugerido
1. Perfil con datos reales, porque es lo más visible y casi todo ya existe.
2. Alertas y Emergencia con Supabase (aquí habría que confirmar las tablas en el esquema).
3. Resumen de turno calculado con las órdenes del día.
4. Ajustes y notificaciones.
