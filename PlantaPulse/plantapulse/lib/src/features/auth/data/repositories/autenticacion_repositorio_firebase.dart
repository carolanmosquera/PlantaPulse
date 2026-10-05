// lib/src/features/auth/data/repositories/autenticacion_repositorio_firebase.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/fallos.dart';
import '../../domain/repositories/autenticacion_repositorio.dart';
import '../datasources/auth_datasource_firebase.dart';

/// Implementa el contrato con Firebase Auth y traduce sus excepciones a
/// FalloAutenticacion / FalloRed: el dominio nunca ve un FirebaseAuthException.
class AutenticacionRepositorioFirebase implements AutenticacionRepositorio {
  final AuthDatasourceFirebase _datasource;

  AutenticacionRepositorioFirebase({AuthDatasourceFirebase? datasource})
      : _datasource = datasource ?? AuthDatasourceFirebase();

  @override
  String? get uidActual => _datasource.usuarioActual?.uid;

  @override
  CuentaAuth? get cuentaActual {
    final u = _datasource.usuarioActual;
    if (u == null) return null;
    return CuentaAuth(uid: u.uid, email: u.email, nombre: u.displayName);
  }

  @override
  bool get haySesion => _datasource.usuarioActual != null;

  @override
  Stream<String?> get cambiosDeSesion =>
      _datasource.cambiosDeSesion.map((u) => u?.uid);

  @override
  Future<String> registrar({required String email, required String password}) =>
      _traducir(() => _datasource.registrar(email: email, password: password));

  @override
  Future<String> entrar({required String email, required String password}) =>
      _traducir(() => _datasource.entrar(email: email, password: password));

  @override
  Future<void> salir() => _traducir(_datasource.salir);

  @override
  Future<void> enviarCorreoDeRecuperacion(String email) =>
      _traducir(() => _datasource.enviarCorreoDeRecuperacion(email));

  Future<T> _traducir<T>(Future<T> Function() operacion) async {
    try {
      return await operacion();
    } on FirebaseAuthException catch (e) {
      final mensaje = mensajeDeError(e);
      throw e.code == 'network-request-failed'
          ? FalloRed(mensaje)
          : FalloAutenticacion(mensaje);
    }
  }

  /// Traduce los códigos de error de Firebase a mensajes en español.
  /// Sin esto el usuario vería "[firebase_auth/invalid-credential] ...".
  static String mensajeDeError(Object e) {
    if (e is! FirebaseAuthException) {
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
    return switch (e.code) {
      'invalid-email'        => 'El correo no tiene un formato válido.',
      'user-disabled'        => 'Esta cuenta está deshabilitada.',
      'user-not-found'       => 'No existe una cuenta con ese correo.',
      'wrong-password'       => 'La contraseña es incorrecta.',
      'invalid-credential'   => 'Correo o contraseña incorrectos.',
      'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
      'weak-password'        => 'La contraseña debe tener al menos 6 caracteres.',
      'network-request-failed' => 'Sin conexión. Revisa tu internet.',
      'too-many-requests'    => 'Demasiados intentos. Espera un momento.',
      _                      => 'No se pudo completar la operación (${e.code}).',
    };
  }
}
