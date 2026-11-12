// lib/src/features/auth/domain/usecases/cerrar_sesion.dart
import '../repositories/autenticacion_repositorio.dart';

class CerrarSesion {
  final AutenticacionRepositorio _auth;

  /// Lo que hay que hacer mientras la sesión todavía sirve, por ejemplo
  /// borrar el token de notificaciones del perfil (RLS ya no lo permite
  /// después de salir). Si falla, igual se cierra la sesión.
  final Future<void> Function()? _antesDeSalir;

  const CerrarSesion(this._auth, {this._antesDeSalir});

  Future<void> ejecutar() async {
    try {
      await _antesDeSalir?.call();
    } catch (_) {}
    await _auth.salir();
  }
}
