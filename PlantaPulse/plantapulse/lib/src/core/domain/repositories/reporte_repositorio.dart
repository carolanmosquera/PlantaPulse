// lib/src/core/domain/repositories/reporte_repositorio.dart
import '../entities/reporte.dart';

/// Reportes de avance. En core porque los leen el detalle de la orden
/// (feature ordenes) y la validación (feature reportes).
abstract class ReporteRepositorio {
  /// Reportes de una orden, los más viejos primero: se leen como una
  /// conversación.
  Stream<List<Reporte>> deLaOrden(String ordenId);

  /// Inserta el reporte. El servidor actualiza la orden solo (contadores,
  /// portada, estado): quien llama NO debe tocar la orden.
  Future<void> crear(Reporte reporte);
}
