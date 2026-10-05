// lib/src/core/sesion/sesion_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

/// La sesión es transversal: el feed, crear orden y el perfil necesitan
/// saber quién está conectado, y perfil y ajustes cierran sesión.
///
/// Para que esos features no importen el feature auth, todos dependen de
/// este tipo. La implementación (AuthBloc) vive en features/auth y main.dart
/// la registra como SesionBloc.
abstract class SesionBloc extends Bloc<AuthEvent, AuthState> {
  SesionBloc() : super(const AuthState());
}
