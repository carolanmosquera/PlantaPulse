// lib/src/features/auth/domain/usecases/perfil_de_cuenta.dart
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';
import '../repositories/autenticacion_repositorio.dart';

/// Auxiliar compartido por ComprobarSesion, IniciarSesion y RecargarPerfil.
///
/// Lee el perfil. Si no existe (la cuenta de Auth se creó pero la
/// escritura del perfil falló), lo recrea como pendiente.
class PerfilDeCuenta {
  final AutenticacionRepositorio _auth;
  final UsuarioRepositorio _usuarios;

  const PerfilDeCuenta(this._auth, this._usuarios);

  Future<Usuario> ejecutar(String uid) async {
    final existente = await _usuarios.obtener(uid);
    if (existente != null) return existente;

    final cuenta = _auth.cuentaActual;
    final recreado = Usuario(
      uid: uid,
      nombre: cuenta?.nombre ?? cuenta?.email?.split('@').first ?? 'Sin nombre',
      email: cuenta?.email ?? '',
      rol: RolUsuario.tecnico,
      estado: EstadoCuenta.pendiente,
      plantaId: '',
      createdAt: DateTime.now(),
    );
    await _usuarios.crear(recreado);
    return recreado;
  }
}
