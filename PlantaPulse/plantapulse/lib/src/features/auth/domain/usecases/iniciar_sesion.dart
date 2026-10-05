// lib/src/features/auth/domain/usecases/iniciar_sesion.dart
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';
import '../repositories/autenticacion_repositorio.dart';
import 'perfil_de_cuenta.dart';

/// Entra con correo y contraseña y devuelve el perfil.
class IniciarSesion {
  final AutenticacionRepositorio _auth;
  final PerfilDeCuenta _perfil;

  IniciarSesion(this._auth, UsuarioRepositorio usuarios)
      : _perfil = PerfilDeCuenta(_auth, usuarios);

  Future<Usuario> ejecutar({
    required String email,
    required String password,
  }) async {
    final uid = await _auth.entrar(email: email, password: password);
    return _perfil.ejecutar(uid);
  }
}
