// lib/src/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

/// Habla SOLO con Firebase Auth: cuentas, contraseñas, sesión.
/// No sabe nada de Firestore ni del modelo Usuario.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// El uid de quien está conectado, o null si nadie lo está.
  String? get uidActual => _auth.currentUser?.uid;

  bool get haySesion => _auth.currentUser != null;

  /// Stream que emite cada vez que alguien entra o sale.
  /// Sirve para decidir en main.dart si arrancar en login o en el feed.
  Stream<User?> get cambiosDeSesion => _auth.authStateChanges();

  /// Crea la cuenta y devuelve el uid.
  /// Ese uid será el ID del documento en la colección 'usuarios'.
  Future<String> registrar({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user!.uid;
  }

  Future<String> entrar({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user!.uid;
  }

  Future<void> salir() => _auth.signOut();

  Future<void> enviarCorreoDeRecuperacion(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

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