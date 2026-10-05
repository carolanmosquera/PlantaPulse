// lib/src/core/core.dart
// Barril de lo que la capa ui de cualquier feature puede usar de core.
// La capa data de core (Firestore) NO se exporta aquí: solo la importan
// las implementaciones de repositorio y main.dart.
export 'components/widgets.dart';
export 'domain/domain.dart';
export 'sesion/sesion_bloc.dart';
export 'theme/app_colors.dart';
export 'theme/estilos_entidades.dart';
export 'theme/rutas.dart';
