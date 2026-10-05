// lib/src/features/auth/domain/usecases/cerrar_sesion.dart
import '../repositories/autenticacion_repositorio.dart';

class CerrarSesion {
  final AutenticacionRepositorio _auth;

  const CerrarSesion(this._auth);

  Future<void> ejecutar() => _auth.salir();
}
