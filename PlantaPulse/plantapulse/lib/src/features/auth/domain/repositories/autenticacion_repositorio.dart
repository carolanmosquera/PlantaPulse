// lib/src/features/auth/domain/repositories/autenticacion_repositorio.dart

/// Datos mínimos de la cuenta autenticada, sin tipos del SDK.
class CuentaAuth {
  final String uid;
  final String? email;
  final String? nombre;

  const CuentaAuth({required this.uid, this.email, this.nombre});
}

/// Cuentas, contraseñas y sesión. No sabe nada del perfil Usuario.
///
/// Los errores llegan como FalloAutenticacion o FalloRed, con el
/// mensaje ya traducido al español.
abstract class AutenticacionRepositorio {
  /// El uid de quien está conectado, o null si nadie lo está.
  String? get uidActual;

  /// La cuenta conectada, o null si nadie lo está.
  CuentaAuth? get cuentaActual;

  bool get haySesion;

  /// Emite el uid cada vez que alguien entra (o null cuando sale).
  Stream<String?> get cambiosDeSesion;

  /// Crea la cuenta y devuelve el uid.
  Future<String> registrar({required String email, required String password});

  Future<String> entrar({required String email, required String password});

  Future<void> salir();

  Future<void> enviarCorreoDeRecuperacion(String email);
}
