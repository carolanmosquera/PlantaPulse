# enviar-push (KAN-97)

Envía la notificación push cuando a un técnico le asignan una orden. La
llama el trigger de `supabase/06_push_asignacion.sql`. La app ya sabe
abrir la orden al tocar la notificación (KAN-96).

## Quién recibe el aviso

Solo el responsable nuevo de la orden, y solo si:

- tiene un dispositivo registrado (`usuarios.fcm_token`),
- en Ajustes no apagó las notificaciones push ni los avisos de órdenes
  (`preferencias_avisos`, KAN-100),
- si marcó "solo críticas", la orden es de prioridad alta o urgente,
- no es quien creó la orden (un supervisor que se asigna una orden a sí mismo).

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

   Luego ejecutar entero `supabase/06_push_asignacion.sql`.

## Cómo probarlo

1. En un celular Android, iniciar sesión como técnico y aceptar el
   permiso de notificaciones. Cerrar la app.
2. Desde otra sesión, como supervisor, crear una orden asignada a ese
   técnico (o reasignar una).
3. Debe llegar "Nueva orden asignada · ORD-… · título". Al tocarla, se
   abre esa orden.

Si no llega: Supabase → Edge Functions → enviar-push → Logs. La respuesta
dice el motivo (`enviado: false, motivo: ...`).

## Pruebas de las reglas

```bash
deno test supabase/functions/enviar-push/reglas_test.ts
```
