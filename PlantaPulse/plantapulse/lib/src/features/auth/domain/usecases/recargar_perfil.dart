// lib/src/features/auth/domain/usecases/recargar_perfil.dart
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';
import '../repositories/autenticacion_repositorio.dart';
import 'perfil_de_cuenta.dart';

/// Relee el perfil de la sesión actual ("Ya me aprobaron, reintentar").
/// Devuelve null si la sesión ya no existe.
class RecargarPerfil {
  final AutenticacionRepositorio _auth;
  final PerfilDeCuenta _perfil;

  RecargarPerfil(this._auth, UsuarioRepositorio usuarios)
      : _perfil = PerfilDeCuenta(_auth, usuarios);

  Future<Usuario?> ejecutar() async {
    final uid = _auth.uidActual;
    if (uid == null) return null;
    return _perfil.ejecutar(uid);
  }
}
