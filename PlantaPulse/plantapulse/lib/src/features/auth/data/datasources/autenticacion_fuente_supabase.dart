// lib/src/features/auth/data/datasources/autenticacion_fuente_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/fallos_supabase.dart';
import '../../../../core/errors/fallos.dart';

/// El único lugar que habla con Supabase Auth: cuentas, contraseñas,
/// sesión. No sabe nada de la tabla 'usuarios' ni del modelo Usuario.
///
/// Traduce sus excepciones a FalloAutenticacion / FalloRed: hacia arriba
/// nunca sale un AuthException. Devuelve datos crudos (uid, correo...),
/// no entidades.
class AutenticacionFuenteSupabase {
  final GoTrueClient _auth;

  AutenticacionFuenteSupabase({GoTrueClient? auth})
      : _auth = auth ?? Supabase.instance.client.auth;

  /// supabase_flutter guarda la sesión en el teléfono: al reabrir la app
  /// ya está aquí, igual que antes.
  String? get uidActual => _auth.currentUser?.id;

  /// Los datos de la cuenta conectada, o null si no hay nadie.
  ({String uid, String? email, String? nombre})? get cuentaActual {
    final u = _auth.currentUser;
    if (u == null) return null;
    return (
      uid: u.id,
      email: u.email,
      nombre: u.userMetadata?['nombre'] as String?,
    );
  }

  /// Emite el uid cada vez que alguien entra, sale (null) o se renueva el
  /// token.
  Stream<String?> get cambiosDeSesion =>
      _auth.onAuthStateChange.map((e) => e.session?.user.id);

  /// Crea la cuenta y devuelve el uid. Con "Confirm email" desactivado en
  /// el panel, signUp deja la sesión iniciada: sin ella no se podría
  /// escribir el perfil.
  Future<String> registrar({
    required String email,
    required String password,
  }) =>
      _traducir(() async {
        final res =
            await _auth.signUp(email: email.trim(), password: password);
        final usuario = res.user;
        // Sin sesión el perfil no se puede escribir (RLS exige auth.uid()).
        // Pasa si "Confirm email" está activo en el panel de Supabase.
        if (usuario == null || res.session == null) {
          throw const FalloAutenticacion(
              'La cuenta se creó pero no se pudo iniciar sesión. '
              'Contacta al administrador.');
        }
        return usuario.id;
      });

  Future<String> entrar({
    required String email,
    required String password,
  }) =>
      _traducir(() async {
        final res = await _auth.signInWithPassword(
            email: email.trim(), password: password);
        return res.user!.id;
      });

  Future<void> salir() => _traducir(_auth.signOut);

  Future<void> enviarCorreoDeRecuperacion(String email) =>
      _traducir(() => _auth.resetPasswordForEmail(email.trim()));

  Future<T> _traducir<T>(Future<T> Function() operacion) async {
    try {
      return await operacion();
    } on AuthRetryableFetchException {
      throw const FalloRed();
    } on AuthException catch (e) {
      throw FalloAutenticacion(mensajeDeError(e));
    } catch (e) {
      throw falloDesdeSupabase(e);
    }
  }

  /// Traduce los errores de Supabase Auth a mensajes en español.
  /// Primero por código (gotrue 2.x lo envía); si no viene, por el texto.
  static String mensajeDeError(AuthException e) {
    final porCodigo = switch (e.code) {
      'invalid_credentials'    => 'Correo o contraseña incorrectos.',
      'user_already_exists' ||
      'email_exists'           => 'Ya existe una cuenta con ese correo.',
      'weak_password'          => 'La contraseña debe tener al menos 6 caracteres.',
      'email_address_invalid' ||
      'validation_failed'      => 'El correo no tiene un formato válido.',
      'user_banned'            => 'Esta cuenta está deshabilitada.',
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' => 'Demasiados intentos. Espera un momento.',
      'email_not_confirmed'    => 'Debes confirmar tu correo antes de entrar.',
      'signup_disabled'        => 'El registro de cuentas está deshabilitado.',
      _                        => null,
    };
    if (porCodigo != null) return porCodigo;

    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (m.contains('already registered')) {
      return 'Ya existe una cuenta con ese correo.';
    }
    if (m.contains('password should be')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (m.contains('network') || m.contains('socket')) {
      return 'Sin conexión. Revisa tu internet.';
    }
    return 'No se pudo completar la operación (${e.code ?? e.statusCode ?? '?'}).';
  }
}
