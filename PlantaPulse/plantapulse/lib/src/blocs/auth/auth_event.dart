// lib/src/blocs/auth/auth_event.dart
import 'package:equatable/equatable.dart';

/// No hay eventos por tecla: login y registro son formularios de envío por lote.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Lo lanza el splash al arrancar.
class AuthComprobarSesion extends AuthEvent {
  const AuthComprobarSesion();
}

/// Lo lanza el login.
class AuthIniciarSesion extends AuthEvent {
  final String email;
  final String password;

  const AuthIniciarSesion({required this.email, required this.password});

  // La contraseña no entra en props: no hace falta para comparar eventos
  // y así no aparece en logs ni en el toString de Equatable.
  @override
  List<Object?> get props => [email];
}

/// Lo lanza el registro.
class AuthRegistrarse extends AuthEvent {
  final String nombre;
  final String email;
  final String password;

  const AuthRegistrarse({
    required this.nombre,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [nombre, email];
}

/// Lo lanza la pantalla de espera ("Ya me aprobaron, reintentar").
class AuthRecargarPerfil extends AuthEvent {
  const AuthRecargarPerfil();
}

/// Lo lanzan perfil, ajustes y la pantalla de rechazo.
class AuthCerrarSesion extends AuthEvent {
  const AuthCerrarSesion();
}
