// lib/src/features/auth/data/repositories/autenticacion_repositorio_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/data/fallos_supabase.dart';
import '../../../../core/errors/fallos.dart';
import '../../domain/repositories/autenticacion_repositorio.dart';
import '../datasources/autenticacion_datasource_supabase.dart';

/// Implementa el contrato con Supabase Auth y traduce sus excepciones a
/// FalloAutenticacion / FalloRed: el dominio nunca ve un AuthException.
class AutenticacionRepositorioSupabase implements AutenticacionRepositorio {
  final AutenticacionDatasourceSupabase _datasource;

  AutenticacionRepositorioSupabase({AutenticacionDatasourceSupabase? datasource})
      : _datasource = datasource ?? AutenticacionDatasourceSupabase();

  @override
  String? get uidActual => _datasource.usuarioActual?.id;

  @override
  CuentaAuth? get cuentaActual {
    final u = _datasource.usuarioActual;
    if (u == null) return null;
    return CuentaAuth(
      uid: u.id,
      email: u.email,
      nombre: u.userMetadata?['nombre'] as String?,
    );
  }

  @override
  bool get haySesion => _datasource.usuarioActual != null;

  @override
  Stream<String?> get cambiosDeSesion =>
      _datasource.cambiosDeSesion.map((e) => e.session?.user.id);

  @override
  Future<String> registrar({required String email, required String password}) =>
      _traducir(() async {
        final res =
            await _datasource.registrar(email: email, password: password);
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

  @override
  Future<String> entrar({required String email, required String password}) =>
      _traducir(() async {
        final res = await _datasource.entrar(email: email, password: password);
        return res.user!.id;
      });

  @override
  Future<void> salir() => _traducir(_datasource.salir);

  @override
  Future<void> enviarCorreoDeRecuperacion(String email) =>
      _traducir(() => _datasource.enviarCorreoDeRecuperacion(email));

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
