// lib/src/features/auth/domain/usecases/solicitudes.dart
// Casos de uso de la bandeja del admin.
import '../../../../core/domain/entities/planta.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/planta_repositorio.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';

/// Solicitudes pendientes en tiempo real, las más nuevas primero.
class ObservarSolicitudesPendientes {
  final UsuarioRepositorio _usuarios;

  const ObservarSolicitudesPendientes(this._usuarios);

  Stream<List<Usuario>> ejecutar() => _usuarios.solicitudesPendientes();
}

class AprobarSolicitud {
  final UsuarioRepositorio _usuarios;

  const AprobarSolicitud(this._usuarios);

  Future<void> ejecutar(
    String uid, {
    required RolUsuario rol,
    required String plantaId,
    required UsuarioRef aprobadoPor,
  }) =>
      _usuarios.aprobar(uid,
          rol: rol, plantaId: plantaId, aprobadoPor: aprobadoPor);
}

class RechazarSolicitud {
  final UsuarioRepositorio _usuarios;

  const RechazarSolicitud(this._usuarios);

  Future<void> ejecutar(String uid, UsuarioRef aprobadoPor) =>
      _usuarios.rechazar(uid, aprobadoPor);
}

/// Plantas para el selector de la hoja de aprobación.
class ListarPlantasActivas {
  final PlantaRepositorio _plantas;

  const ListarPlantasActivas(this._plantas);

  Future<List<Planta>> ejecutar() => _plantas.activas();
}
