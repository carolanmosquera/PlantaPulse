# HU: consultar perfil y conservar preferencias

Implementación integrada con `main` en `feat/ver-configurar-perfil`. Para las preferencias de avisos se necesita la migración `supabase/05_preferencias_avisos.sql` incorporada por KAN-100. Se conservan las dependencias y versiones fijadas por `main`.

## Funcionamiento

En **Perfil**, `ConsultarPerfil` obtiene el usuario de la sesión mediante `UsuarioRepositorio.obtener(uid)` y resuelve su planta mediante `PlantaRepositorio.obtener(id)`, incluso si está inactiva. Muestra nombre, etiqueta del rol, planta, especialidad y, cuando existen, correo y turno. Los campos sin asignar tienen textos explicativos; los errores permiten reintentar. Solo el administrador ve Solicitudes de registro.

En **Ajustes de Cuenta**, un `AjustesBloc` nuevo por pantalla y cuenta carga las preferencias del servidor. El interruptor cambia inmediatamente, muestra **Guardando…** y bloquea controles y navegación dentro de la app hasta recibir respuesta. Si falla, restaura el estado anterior, informa del error y permite volver a cargar. Una carga fallida no muestra valores iniciales como si fueran datos guardados.

El módulo sigue las capas del proyecto:

`Pantalla → BLoC → casos de uso → contrato de repositorio → implementación → fuente Supabase`

`main.dart` registra las dependencias. El repositorio de preferencias se puede sustituir en pruebas.

## Persistencia y permisos

Para **Modo Oscuro** y **Modo Offline**, la fuente lee la cuenta con `auth.getUser()` y guarda mediante `auth.updateUser(UserAttributes(data: ...))`, con el token de la sesión existente. Verifica que el identificador corresponda a esa cuenta y confirma el valor devuelto por Supabase.

**Push**, **Mantenimiento** y **Solo Críticas** se leen y guardan en `usuarios.preferencias_avisos`, fuente de verdad para los avisos. La lectura posterior al guardado confirma el valor. La migración permite actualizar esta columna únicamente al titular del perfil mediante el trigger `proteger_usuarios` y RLS existentes. Al cambiar Push, `SincronizarTokenPush` retira o registra el token FCM.

Auth recibe exclusivamente cambios de `modo_oscuro` o `modo_offline` dentro de `user_metadata.plantapulse_preferencias`. Supabase conserva otros metadatos y claves desconocidas, incluidas las claves antiguas de avisos; estas últimas ya no gobiernan las notificaciones. No se envían cambios de rol, correo ni contraseña. Los roles siguen viniendo de `usuarios` y los metadatos de preferencias nunca conceden permisos.

| Preferencia | Fuente y clave | Valor inicial |
| --- | --- | --- |
| Notificaciones Push | `usuarios.preferencias_avisos.push` | Activado |
| Alertas de Mantenimiento | `usuarios.preferencias_avisos.mantenimiento` | Activado |
| Solo Críticas | `usuarios.preferencias_avisos.soloCriticas` | Desactivado |
| Modo Oscuro | Auth `modo_oscuro` | Desactivado |
| Modo Offline | Auth `modo_offline` | Desactivado |

Los valores iniciales se usan tras una lectura exitosa cuando la cuenta aún no tiene la opción. Al reabrir Ajustes se consulta nuevamente el servidor. No se comparte estado de preferencias entre cuentas.

El modo oscuro cambia la apariencia de la aplicación. Push registra o retira el dispositivo; los filtros de avisos quedan guardados para que los emisores de notificaciones los consulten. El modo offline solo guarda la preferencia y todavía no sincroniza datos sin conexión. Para leer y guardar se necesita conexión.

## Modo oscuro y alcance del diff

`AppColors` y `AppText` conservan sus valores originales. Sus extensiones `segunTema(context)` adaptan únicamente los colores al tema de Material; `AppTheme` define las variantes clara y oscura. Los mismos componentes siguen dibujando tarjetas, campos, botones y pantallas. No se invierten las fotos ni se cambian los colores de marca de los botones rellenos con texto blanco.

`TemaCubit`, dentro de la presentación de perfil, carga la preferencia al iniciar una sesión activa. `AjustesBloc` sigue siendo responsable del guardado; la pantalla comunica al tema tanto el cambio inmediato como la restauración ante error. Las respuestas tardías de una carga anterior no sobrescriben el tema de otra cuenta ni una selección más reciente. Al cerrar sesión se vuelve a claro; las pantallas públicas de acceso mantienen su diseño original. Si falla la carga inicial, la app puede abrirse en claro y Ajustes permite recuperar la preferencia del servidor sin sobrescribirla.

El modo oscuro requiere modificar referencias de color en componentes y pantallas compartidas porque el código original usaba colores fijos. Esos cambios se limitan a la apariencia, a retirar `const` cuando el color depende del tema y a pasar `BuildContext` a los auxiliares que lo necesitan. No se reformatearon globalmente los archivos ni se alteraron las reglas de órdenes, reportes, roles o RLS. Las pruebas existentes reciben el repositorio falso de preferencias porque ahora el tema se carga al entrar.

Para revisar el PR conviene distinguir perfil/preferencias de su integración con el modo oscuro. La revisión local del diff reduce cambios innecesarios; no garantiza ausencia de conflictos con cambios posteriores de otros integrantes en la rama destino.

## Validación automática

Desde `PlantaPulse/plantapulse`:

```powershell
flutter test --no-pub
flutter analyze --no-pub
flutter analyze --no-pub --no-fatal-infos
```

- Suite completa integrada: **106 pruebas aprobadas**, incluidas autenticación, navegación, órdenes, reportes, push y alertas críticas con GPS simulado.
- Pruebas añadidas: perfil de técnico, supervisor y administrador; datos vacíos, reintentos, los cinco interruptores, regreso a Ajustes, nueva instancia, cierre de sesión, aislamiento de cuentas, bloqueo durante guardado y restauración ante error.
- Fuente Auth probada con HTTP simulado: token de sesión, GET/PUT de las opciones oscuridad y offline, preservación de metadatos, rechazo sin sesión o con otra cuenta, errores y confirmación. Las pruebas de avisos verifican la persistencia en el repositorio de usuarios y el efecto sobre el token push con dobles en memoria. También se comprueba la consulta por id de una planta inactiva.
- Modo oscuro: restauración por cuenta al iniciar sesión, aislamiento entre cuentas, lecturas tardías, cambio inmediato, restauración visual al fallar el guardado, contraste de texto/superficies, conservación del tema claro y herencia del tema en diálogos.
- Análisis integrado: **0 errores, 0 advertencias y 65 avisos informativos** con Flutter 3.50; `--no-fatal-infos` terminó con código 0. Los avisos informativos provienen sobre todo de la deprecación de `material.dart` en esta versión. No se desactivan reglas. El comando sin `--no-fatal-infos` devuelve código 1 por esos avisos.
- `flutter build web --no-pub`: compilación correcta. `flutter pub get --enforce-lockfile` descargó las versiones fijadas, aunque informó que Windows necesita Modo desarrollador para enlaces simbólicos de plugins.
- Los tests de interfaces usan datos simulados. En el paso por el login existente se tolera únicamente su desbordamiento de texto con la fuente de pruebas Ahem; los errores de Perfil y Ajustes siguen haciendo fallar las pruebas.

## Comprobación con tu cuenta real y evidencia para Jira

```powershell
cd "C:\Users\santi\Desktop\7\GERENCIA TI\PlantaPulse\PlantaPulse\plantapulse"
flutter run --no-pub -d chrome
```

1. Inicia sesión con una cuenta aprobada, sin compartir su contraseña en el chat.
   Antes, confirma que el entorno de Supabase tenga aplicada `supabase/05_preferencias_avisos.sql`.
2. Abre **Perfil** en la barra inferior. Comprueba nombre, rol, planta y especialidad; captura esa pantalla.
3. Entra en **Ajustes de Cuenta**. Cambia cada interruptor y espera **Preferencia guardada** antes de salir. Al activar **Modo Oscuro** deben cambiar inmediatamente los colores; comprueba también Perfil, Feed y un formulario o diálogo. Al desactivarlo debe regresar la paleta clara original.
4. Regresa al perfil y vuelve a Ajustes. Comprueba los cinco valores y toma una captura.
5. Cierra sesión, entra con la misma cuenta y comprueba de nuevo. Si dispones de otra cuenta aprobada, verifica también que sus opciones sean independientes.
6. Para comprobar el fallo de guardado, abre Ajustes con conexión, desconecta la red y cambia una opción. Debe mostrarse un error y restaurarse el valor anterior; reconecta y pulsa **Volver a cargar** para consultar el estado del servidor.
7. Adjunta en Jira capturas de la app y del código relevante: `perfil_screen.dart`, `ajustes_bloc.dart` y `preferencias_fuente_supabase.dart` dentro de `lib/src/features/perfil/`.
8. Solicita revisión a otro integrante y actualiza el tablero según KAN-134.

**Pendiente para completar el DoD:** validar con una sesión real de Supabase (incluidos los permisos del rol y la migración), comprobar push y GPS en Android, adjuntar evidencias y obtener la revisión del equipo. Este equipo no tiene Android SDK. Las pruebas simuladas no sustituyen esos pasos. No se han publicado evidencias ni cambiado estados en Jira.
