// lib/src/features/auth/data/repositories/autenticacion_repositorio_impl.dart
import '../../domain/repositories/autenticacion_repositorio.dart';
import '../datasources/autenticacion_fuente_supabase.dart';

/// Implementación del contrato. No sabe qué servicio de autenticación hay
/// debajo: la fuente ya entrega los errores como FalloAutenticacion /
/// FalloRed, y aquí solo se arma la CuentaAuth del dominio.
class AutenticacionRepositorioImpl implements AutenticacionRepositorio {
  final AutenticacionFuenteSupabase _fuente;

  AutenticacionRepositorioImpl(this._fuente);

  @override
  String? get uidActual => _fuente.uidActual;

  @override
  CuentaAuth? get cuentaActual {
    final c = _fuente.cuentaActual;
    if (c == null) return null;
    return CuentaAuth(uid: c.uid, email: c.email, nombre: c.nombre);
  }

  @override
  bool get haySesion => _fuente.uidActual != null;

  @override
  Stream<String?> get cambiosDeSesion => _fuente.cambiosDeSesion;

  @override
  Future<String> registrar({required String email, required String password}) =>
      _fuente.registrar(email: email, password: password);

  @override
  Future<String> entrar({required String email, required String password}) =>
      _fuente.entrar(email: email, password: password);

  @override
  Future<void> salir() => _fuente.salir();

  @override
  Future<void> enviarCorreoDeRecuperacion(String email) =>
      _fuente.enviarCorreoDeRecuperacion(email);
}
