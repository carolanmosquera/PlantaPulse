// lib/src/features/perfil/domain/usecases/actualizar_perfil.dart
import '../../../../core/domain/repositories/usuario_repositorio.dart';

/// Cambia los datos personales del perfil (nombre, foto, turno...).
/// Rol, estado y planta NO se cambian aquí: eso lo hace el admin.
class ActualizarPerfil {
  final UsuarioRepositorio _usuarios;

  const ActualizarPerfil(this._usuarios);

  Future<void> ejecutar(String uid, Map<String, dynamic> cambios) =>
      _usuarios.actualizar(uid, cambios);
}
