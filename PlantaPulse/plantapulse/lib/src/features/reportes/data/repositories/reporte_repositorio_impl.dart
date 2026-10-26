// lib/src/features/reportes/data/repositories/reporte_repositorio_impl.dart
import '../../../../core/data/models/reporte_modelo.dart';
import '../../../../core/domain/entities/reporte.dart';
import '../../../../core/domain/repositories/reporte_repositorio.dart';
import '../datasources/reporte_fuente_supabase.dart';

/// Implementación del contrato. No sabe qué base de datos hay debajo:
/// traduce filas a entidades y ordena en Dart.
class ReporteRepositorioImpl implements ReporteRepositorio {
  final ReporteFuenteSupabase _fuente;

  ReporteRepositorioImpl(this._fuente);

  /// Los más viejos primero, ordenados sobre DateTime (no sobre el texto).
  @override
  Stream<List<Reporte>> deLaOrden(String ordenId) =>
      _fuente.deLaOrden(ordenId).map((filas) =>
          filas.map(ReporteModelo.fromJson).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

  @override
  Future<void> crear(Reporte reporte) =>
      _fuente.insertar(ReporteModelo.desdeEntidad(reporte).toJson());
}
