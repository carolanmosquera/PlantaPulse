// lib/src/core/domain/repositories/planta_repositorio.dart
import '../entities/planta.dart';

/// Plantas. Se crean desde la consola; la app solo las lee.
abstract class PlantaRepositorio {
  /// Planta asignada al perfil, aunque ya no esté activa en el catálogo.
  Future<Planta?> obtener(String id);

  /// Plantas activas ordenadas por nombre, para el selector del admin.
  Future<List<Planta>> activas();
}
