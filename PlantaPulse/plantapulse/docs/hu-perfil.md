# HU: consultar perfil y conservar preferencias

Implementación en `feat/ver-configurar-perfil`. No requiere migraciones SQL ni cambios de versiones o dependencias.

## Funcionamiento

En **Perfil**, `ConsultarPerfil` obtiene el usuario de la sesión mediante `UsuarioRepositorio.obtener(uid)` y resuelve su planta mediante `PlantaRepositorio.obtener(id)`, incluso si está inactiva. Muestra nombre, etiqueta del rol, planta, especialidad y, cuando existen, correo y turno. Los campos sin asignar tienen textos explicativos; los errores permiten reintentar. Solo el administrador ve Solicitudes de registro.

En **Ajustes de Cuenta**, un `AjustesBloc` nuevo por pantalla y cuenta carga las preferencias del servidor. El interruptor cambia inmediatamente, muestra **Guardando…** y bloquea controles y navegación dentro de la app hasta recibir respuesta. Si falla, restaura el estado anterior, informa del error y permite volver a cargar. Una carga fallida no muestra valores iniciales como si fueran datos guardados.

El módulo sigue las capas del proyecto:

`Pantalla → BLoC → casos de uso → contrato de repositorio → implementación → fuente Supabase`

`main.dart` registra las dependencias. El repositorio de preferencias se puede sustituir en pruebas.

## Persistencia y permisos

La fuente lee la cuenta con `auth.getUser()` y guarda mediante `auth.updateUser(UserAttributes(data: ...))`, con el token de la sesión existente. Verifica que el identificador corresponda a esa cuenta y confirma el valor devuelto por Supabase.

Se actualiza exclusivamente `user_metadata.plantapulse_preferencias`. Supabase combina esa clave con el resto de metadatos; dentro de ella se conservan las otras opciones, incluidas claves desconocidas. No se envían cambios de rol, correo ni contraseña. Los roles siguen viniendo del perfil en `usuarios`; las consultas a `usuarios` y `plantas` mantienen las políticas RLS existentes. Los metadatos de preferencias nunca se usan para conceder permisos.

| Preferencia | Clave | Valor inicial |
| --- | --- | --- |
| Notificaciones Push | `notificaciones_push` | Activado |
| Alertas de Mantenimiento | `alertas_mantenimiento` | Activado |
| Solo Críticas | `solo_criticas` | Desactivado |
| Modo Oscuro | `modo_oscuro` | Desactivado |
| Modo Offline | `modo_offline` | Desactivado |

Los valores iniciales se usan tras una lectura exitosa cuando la cuenta aún no tiene la opción. Al reabrir Ajustes se consulta nuevamente el servidor. No se comparte estado de preferencias entre cuentas.

El modo oscuro cambia la apariencia de la aplicación. Las demás opciones conservan preferencias, pero no implementan envío de notificaciones ni sincronización offline. La pantalla explica ese alcance. Para leer y guardar se necesita conexión.

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

- Suite completa: **87 pruebas aprobadas**, incluidas autenticación, navegación, órdenes y reportes.
- Pruebas añadidas: perfil de técnico, supervisor y administrador; datos vacíos, reintentos, los cinco interruptores, regreso a Ajustes, nueva instancia, cierre de sesión, aislamiento de cuentas, bloqueo durante guardado y restauración ante error.
- Fuente Supabase probada con HTTP simulado: token de sesión, GET/PUT, preservación de metadatos, rechazo sin sesión o con otra cuenta, errores y confirmación del valor guardado. También se comprueba la consulta por id de una planta inactiva.
- Modo oscuro: restauración por cuenta al iniciar sesión, aislamiento entre cuentas, lecturas tardías, cambio inmediato, restauración visual al fallar el guardado, contraste de texto/superficies, conservación del tema claro y herencia del tema en diálogos.
- Análisis final: **0 errores, 0 advertencias y 62 avisos informativos** con Flutter 3.50; `--no-fatal-infos` terminó con código 0. La versión de perfil/preferencias tenía 60; los dos avisos adicionales corresponden a la importación Material en el nuevo tema y su prueba de componentes. No se desactivan reglas en `analysis_options.yaml`. El comando sin `--no-fatal-infos` devuelve código 1 por los avisos informativos.
- Los tests de interfaces usan datos simulados. En el paso por el login existente se tolera únicamente su desbordamiento de texto con la fuente de pruebas Ahem; los errores de Perfil y Ajustes siguen haciendo fallar las pruebas.

## Comprobación con tu cuenta real y evidencia para Jira

```powershell
cd "C:\Users\santi\Desktop\7\GERENCIA TI\PlantaPulse\PlantaPulse\plantapulse"
flutter run --no-pub -d chrome
```

1. Inicia sesión con una cuenta aprobada, sin compartir su contraseña en el chat.
2. Abre **Perfil** en la barra inferior. Comprueba nombre, rol, planta y especialidad; captura esa pantalla.
3. Entra en **Ajustes de Cuenta**. Cambia cada interruptor y espera **Preferencia guardada** antes de salir. Al activar **Modo Oscuro** deben cambiar inmediatamente los colores; comprueba también Perfil, Feed y un formulario o diálogo. Al desactivarlo debe regresar la paleta clara original.
4. Regresa al perfil y vuelve a Ajustes. Comprueba los cinco valores y toma una captura.
5. Cierra sesión, entra con la misma cuenta y comprueba de nuevo. Si dispones de otra cuenta aprobada, verifica también que sus opciones sean independientes.
6. Para comprobar el fallo de guardado, abre Ajustes con conexión, desconecta la red y cambia una opción. Debe mostrarse un error y restaurarse el valor anterior; reconecta y pulsa **Volver a cargar** para consultar el estado del servidor.
7. Adjunta en Jira capturas de la app y del código relevante: `perfil_screen.dart`, `ajustes_bloc.dart` y `preferencias_fuente_supabase.dart` dentro de `lib/src/features/perfil/`.
8. Solicita revisión a otro integrante y actualiza el tablero según KAN-134.

**Pendiente para completar el DoD:** validar con una sesión real de Supabase (incluidos los permisos del rol), adjuntar evidencias y obtener la revisión del equipo. Las pruebas simuladas no sustituyen esos pasos. No se han publicado evidencias ni cambiado estados en Jira.
