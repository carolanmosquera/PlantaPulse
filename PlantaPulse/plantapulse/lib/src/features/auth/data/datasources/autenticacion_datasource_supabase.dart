// lib/src/features/auth/data/datasources/autenticacion_datasource_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Habla SOLO con Supabase Auth: cuentas, contraseñas, sesión.
/// No sabe nada de la tabla 'usuarios' ni del modelo Usuario.
class AutenticacionDatasourceSupabase {
  final GoTrueClient _auth;

  AutenticacionDatasourceSupabase({GoTrueClient? auth})
      : _auth = auth ?? Supabase.instance.client.auth;

  /// supabase_flutter guarda la sesión en el teléfono: al reabrir la app
  /// ya está aquí, igual que antes.
  User? get usuarioActual => _auth.currentUser;

  /// Emite cada vez que alguien entra, sale o se renueva el token.
  Stream<AuthState> get cambiosDeSesion => _auth.onAuthStateChange;

  /// Crea la cuenta. Con "Confirm email" desactivado en el panel, signUp
  /// deja la sesión iniciada: sin ella no se podría escribir el perfil.
  Future<AuthResponse> registrar({
    required String email,
    required String password,
  }) =>
      _auth.signUp(email: email.trim(), password: password);

  Future<AuthResponse> entrar({
    required String email,
    required String password,
  }) =>
      _auth.signInWithPassword(email: email.trim(), password: password);

  Future<void> salir() => _auth.signOut();

  Future<void> enviarCorreoDeRecuperacion(String email) =>
      _auth.resetPasswordForEmail(email.trim());
}
