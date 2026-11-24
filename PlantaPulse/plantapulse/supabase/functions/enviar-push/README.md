# enviar-push (KAN-97 y KAN-95)

Envía las notificaciones push de órdenes. La app ya sabe abrir la orden
al tocar cualquiera de ellas (KAN-96).

| Aviso | Para quién | Quién llama a la función |
| --- | --- | --- |
| Orden asignada (KAN-97) | El técnico responsable | El trigger de `supabase/06_push_asignacion.sql` |
| Orden crítica sin avance (KAN-95) | Los supervisores de la planta | El cron de `supabase/07_recordatorios_estancadas.sql`, cada 15 minutos |

## Quién recibe el aviso de asignación

Solo el responsable nuevo de la orden, y solo si:

- tiene un dispositivo registrado (`usuarios.fcm_token`),
- en Ajustes no apagó las notificaciones push ni los avisos de órdenes
  (`preferencias_avisos`, KAN-100),
- si marcó "solo críticas", la orden es de prioridad alta o urgente,
- no es quien creó la orden (un supervisor que se asigna una orden a sí mismo).

## Quién recibe el recordatorio de órdenes estancadas

Una orden está estancada si es **crítica** (prioridad Urgente o estado
crítica), sigue **abierta** (ni en validación ni completada) y su último
reporte, o su creación si no tiene, fue hace **más de 4 horas**.

Se avisa a cada **supervisor activo de la planta** que tenga teléfono
registrado y no haya apagado las notificaciones push ni los avisos de
órdenes. "Solo críticas" no lo deja por fuera, porque la orden es crítica.

El recordatorio se repite cada 4 horas mientras la orden siga sin
reportes. Si recibe un reporte, el conteo empieza de nuevo.

## Puesta en marcha (una sola vez)

1. **Cuenta de servicio de Firebase.** Consola de Firebase → Configuración
   del proyecto → Cuentas de servicio → *Generar nueva clave privada*.
   Descarga un JSON. **No se sube al repositorio.**
2. **Secretos de la función** (Supabase CLI, desde `plantapulse/`):

   ```bash
   supabase secrets set --project-ref uxajglpaoofragjxcrvx FCM_SERVICE_ACCOUNT="$(cat ruta/al/archivo.json)"
   supabase secrets set --project-ref uxajglpaoofragjxcrvx PUSH_WEBHOOK_SECRET="<un valor largo y aleatorio>"
   ```

3. **Desplegar la función.** Sin verificación de JWT, porque la llama la
   base con el secreto propio, no un usuario:

   ```bash
   supabase functions deploy enviar-push --project-ref uxajglpaoofragjxcrvx --no-verify-jwt
   ```

4. **En el SQL Editor**: guardar el MISMO secreto en el Vault y ejecutar
   el archivo del trigger:

   ```sql
   select vault.create_secret('<el mismo valor del paso 2>', 'push_webhook_secret');
   ```

   Luego ejecutar enteros `supabase/06_push_asignacion.sql` (KAN-97) y
   `supabase/07_recordatorios_estancadas.sql` (KAN-95).

## Cómo probarlo

1. En un celular Android, iniciar sesión como técnico y aceptar el
   permiso de notificaciones. Cerrar la app.
2. Desde otra sesión, como supervisor, crear una orden asignada a ese
   técnico (o reasignar una).
3. Debe llegar "Nueva orden asignada · ORD-… · título". Al tocarla, se
   abre esa orden.

Si no llega: Supabase → Edge Functions → enviar-push → Logs. La respuesta
dice el motivo (`enviado: false, motivo: ...`).

### Recordatorio de órdenes estancadas (KAN-95)

Para no esperar 4 horas, en el SQL Editor se puede envejecer una orden de
prueba (crítica, sin reportes):

```sql
update ordenes set created_at = now() - interval '5 hours' where codigo = 'ORD-XXXX';
select * from public.ordenes_estancadas(4);      -- debe aparecer
select public.revisar_ordenes_estancadas();      -- envía sin esperar al cron
```

Al supervisor de esa planta le llega "Orden crítica sin avance · ORD-… lleva
5 h sin reportes". Si se vuelve a ejecutar, ya no sale de nuevo hasta dentro
de 4 horas.

## Pruebas de las reglas

```bash
deno test supabase/functions/enviar-push/reglas_test.ts
```
