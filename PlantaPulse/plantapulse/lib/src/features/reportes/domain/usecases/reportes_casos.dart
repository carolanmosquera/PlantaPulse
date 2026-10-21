// lib/src/features/reportes/domain/usecases/reportes_casos.dart
// Casos de uso del ciclo del reporte: el técnico documenta, el supervisor
// valida y cierra (o devuelve). SubirEvidencia vive en core
// (core/domain/usecases/evidencias.dart): crear orden también sube fotos.
import '../../../../core/domain/entities/reporte.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';
import '../../../../core/domain/repositories/reporte_repositorio.dart';

/// Inserta el reporte con las rutas ya subidas. La orden NO se toca: el
/// servidor la actualiza solo y el cambio vuelve por el stream.
class PublicarReporte {
  final ReporteRepositorio _reportes;

  const PublicarReporte(this._reportes);

  Future<void> ejecutar(Reporte reporte) => _reportes.crear(reporte);
}

/// "Aprobar y cerrar".
class CerrarOrden {
  final OrdenRepositorio _ordenes;

  const CerrarOrden(this._ordenes);

  Future<void> ejecutar({
    required String ordenId,
    required UsuarioRef validadaPor,
    String observaciones = '',
  }) =>
      _ordenes.cerrar(
        ordenId: ordenId,
        validadaPor: validadaPor,
        observaciones: observaciones,
      );
}

/// "Solicitar correcciones": las observaciones son obligatorias, el
/// técnico tiene que saber qué corregir.
class DevolverOrden {
  final OrdenRepositorio _ordenes;

  const DevolverOrden(this._ordenes);

  Future<void> ejecutar({
    required String ordenId,
    required String observaciones,
  }) =>
      _ordenes.devolver(ordenId: ordenId, observaciones: observaciones);
}
