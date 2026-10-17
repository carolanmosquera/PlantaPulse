// lib/src/core/domain/repositories/categoria_repositorio.dart
import '../entities/categoria.dart';

/// Categorías de orden. En core porque las usan crear_orden (elegir y
/// crear) y ordenes (cambiarla al editar una orden).
abstract class CategoriaRepositorio {
  /// Categorías activas de la planta, ordenadas por nombre.
  Future<List<Categoria>> deLaPlanta(String plantaId);

  /// Crea la categoría y la devuelve con el id que le asignó la base.
  /// Un nombre repetido en la planta (sin importar mayúsculas) llega
  /// como FalloApp con un mensaje que lo dice.
  Future<Categoria> crear(Categoria categoria);
}
