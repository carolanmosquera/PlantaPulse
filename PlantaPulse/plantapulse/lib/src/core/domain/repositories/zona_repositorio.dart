// lib/src/core/domain/repositories/zona_repositorio.dart
import '../entities/planta.dart';

/// Zonas de una planta. Las da de alta el admin; la app solo las lee.
abstract class ZonaRepositorio {
  /// Zonas activas de la planta, ordenadas por nombre.
  Future<List<Zona>> deLaPlanta(String plantaId);
}
