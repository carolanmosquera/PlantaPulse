// lib/src/core/sesion/auth_state.dart
import 'package:equatable/equatable.dart';
import '../domain/entities/usuario.dart';

/// A qué pantalla pertenece este usuario.
enum EstadoSesion { desconocida, sinCuenta, pendiente, rechazada, activa }

/// Qué está pasando con el formulario en curso.
enum EstadoAccion { inactiva, enviando, error }

/// Dos campos separados y no un solo enum: así se puede representar
/// "login en curso" (enviando + sinCuenta), y un error de credenciales
/// no borra la sesión existente.
///
/// Regla: cuando algo falla se emite `accion: error` y `sesion` NO se toca.
class AuthState extends Equatable {
  final EstadoSesion sesion;
  final EstadoAccion accion;
  final Usuario? usuario;
  final String? mensajeError;

  const AuthState({
    this.sesion = EstadoSesion.desconocida,
    this.accion = EstadoAccion.inactiva,
    this.usuario,
    this.mensajeError,
  });

  bool get cargando => accion == EstadoAccion.enviando;
  bool get hayError => accion == EstadoAccion.error;
  bool get esAdmin => usuario?.rol.esAdmin ?? false;

  /// `?? this.x` no permite volver un campo a nulo; para eso están
  /// `limpiarUsuario` y `limpiarError`.
  AuthState copyWith({
    EstadoSesion? sesion,
    EstadoAccion? accion,
    Usuario? usuario,
    String? mensajeError,
    bool limpiarUsuario = false,
    bool limpiarError = false,
  }) =>
      AuthState(
        sesion: sesion ?? this.sesion,
        accion: accion ?? this.accion,
        usuario: limpiarUsuario ? null : (usuario ?? this.usuario),
        mensajeError: limpiarError ? null : (mensajeError ?? this.mensajeError),
      );

  // Usuario no implementa ==, así que se compara por uid, estado y rol:
  // basta para detectar que el perfil cambió tras recargarlo.
  @override
  List<Object?> get props => [
        sesion,
        accion,
        usuario?.uid,
        usuario?.estado,
        usuario?.rol,
        mensajeError,
      ];
}
