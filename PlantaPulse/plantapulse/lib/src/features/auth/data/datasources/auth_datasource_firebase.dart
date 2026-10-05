// lib/src/features/auth/data/datasources/auth_datasource_firebase.dart
import 'package:firebase_auth/firebase_auth.dart';

/// Habla SOLO con Firebase Auth: cuentas, contraseñas, sesión.
/// No sabe nada de Firestore ni del modelo Usuario.
/// (Antes se llamaba AuthService.)
class AuthDatasourceFirebase {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get usuarioActual => _auth.currentUser;

  /// Stream que emite cada vez que alguien entra o sale.
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
}
