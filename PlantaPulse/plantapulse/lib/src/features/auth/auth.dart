// lib/src/features/auth/auth.dart
// Barril público del feature: dominio y ui. La capa data NO se exporta:
// solo main.dart conoce las implementaciones concretas.
export 'domain/repositories/autenticacion_repositorio.dart';
export 'domain/usecases/cerrar_sesion.dart';
export 'domain/usecases/comprobar_sesion.dart';
export 'domain/usecases/iniciar_sesion.dart';
export 'domain/usecases/recargar_perfil.dart';
export 'domain/usecases/registrar_solicitud.dart';
export 'domain/usecases/solicitudes.dart';
export 'ui/bloc/auth_bloc.dart';
export 'ui/screens/espera_aprobacion_screen.dart';
export 'ui/screens/login_screen.dart';
export 'ui/screens/registro_screen.dart';
export 'ui/screens/solicitudes_screen.dart';
export 'ui/screens/splash_screen.dart';
