// lib/src/features/auth/domain/usecases/comprobar_sesion.dart
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';
import '../repositories/autenticacion_repositorio.dart';
import 'perfil_de_cuenta.dart';

/// Al arrancar: ¿hay una sesión guardada? Devuelve su perfil, o null
/// si nadie está conectado.
class ComprobarSesion {
  final AutenticacionRepositorio _auth;
  final PerfilDeCuenta _perfil;

  ComprobarSesion(this._auth, UsuarioRepositorio usuarios)
      : _perfil = PerfilDeCuenta(_auth, usuarios);

  Future<Usuario?> ejecutar() async {
    final uid = _auth.uidActual;
    if (uid == null) return null;
    return _perfil.ejecutar(uid);
  }
}
