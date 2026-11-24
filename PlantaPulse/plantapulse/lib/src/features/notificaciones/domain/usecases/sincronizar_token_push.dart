// lib/src/features/notificaciones/domain/usecases/sincronizar_token_push.dart
import 'dart:async';
import '../../../../core/domain/repositories/push_repositorio.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';

/// Mantiene el token del dispositivo guardado en el perfil del usuario
/// conectado (DoD de KAN-96: "el token se guarda y se actualiza").
///
/// - [iniciar] se llama cuando la sesión queda activa.
/// - [detener] se llama ANTES de cerrar sesión: después ya no hay permiso
///   (RLS) para borrar el token del perfil, y el teléfono le seguiría
///   llegando al usuario anterior (el mismo problema de KAN-118).
///
/// Nada de esto debe impedir entrar o salir de la app: si algo falla,
/// la app sigue funcionando, solo que sin notificaciones.
class SincronizarTokenPush {
  final PushRepositorio _push;
  final UsuarioRepositorio _usuarios;

  SincronizarTokenPush(this._push, this._usuarios);

  String? _uid;
  StreamSubscription<String>? _renovaciones;

  /// Pide permiso, guarda el token y se queda escuchando sus cambios.
  /// Llamarlo dos veces con el mismo usuario no hace nada.
  Future<void> iniciar(String uid) async {
    if (_uid == uid) return;
    await _soltar();
    _uid = uid;
    try {
      final token = await _push.activar();
      if (token == null || _uid != uid) return;
      await _usuarios.guardarTokenPush(uid, token);
      _renovaciones = _push.tokenRenovado.listen(
        (nuevo) => _guardarSinFallar(uid, nuevo),
        onError: (_) {},
      );
    } catch (_) {
      // Sin permiso, sin red o sin Firebase: se sigue sin notificaciones
    }
  }

  /// Borra el token del perfil y del dispositivo. Va antes del signOut.
  Future<void> detener() async {
    final uid = _uid;
    await _soltar();
    if (uid == null) return;
    try {
      await _usuarios.borrarTokenPush(uid);
      await _push.desactivar();
    } catch (_) {
      // Si falla, el cierre de sesión debe seguir de todas formas
    }
  }

  Future<void> _guardarSinFallar(String uid, String token) async {
    try {
      await _usuarios.guardarTokenPush(uid, token);
    } catch (_) {}
  }

  Future<void> _soltar() async {
    _uid = null;
    await _renovaciones?.cancel();
    _renovaciones = null;
  }
}
