// lib/src/features/auth/domain/usecases/registrar_solicitud.dart
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';
import '../repositories/autenticacion_repositorio.dart';

/// Crea la cuenta y su perfil pendiente de aprobación.
///
/// La contraseña solo viaja al servicio de autenticación.
/// Nunca se escribe en el perfil.
class RegistrarSolicitud {
  final AutenticacionRepositorio _auth;
  final UsuarioRepositorio _usuarios;

  const RegistrarSolicitud(this._auth, this._usuarios);

  Future<Usuario> ejecutar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    // 1. La cuenta en Auth: el servicio guarda solo el hash de la contraseña
    final uid = await _auth.registrar(email: email, password: password);

    // 2. El perfil, SIN contraseña, pendiente de aprobación
    final nuevo = Usuario(
      uid: uid,
      nombre: nombre.trim(),
      email: email.trim(),
      rol: RolUsuario.tecnico,
      estado: EstadoCuenta.pendiente,
      plantaId: '',
      createdAt: DateTime.now(),
    );
    await _usuarios.crear(nuevo);
    return nuevo;
  }
}
