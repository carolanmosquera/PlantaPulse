
import '../../../../core/domain/entities/reporte.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';
import '../../../../core/domain/repositories/reporte_repositorio.dart';
import '../../../../core/errors/fallos.dart';
import '../../../../core/offline/servicio_offline.dart';

class PublicarReporte {
  final ReporteRepositorio _reportes;
  final ServicioOffline? _offline;

  const PublicarReporte(
    this._reportes, {
    ServicioOffline? servicioOffline,
  }) : _offline = servicioOffline;

  // Devuelve true cuando se publicó en Supabase.
  // Devuelve false cuando quedó pendiente en el dispositivo.
  Future<bool> ejecutar(Reporte reporte) async {
    if (_offline != null && !_offline.conectado) {
      await _offline.guardarReportePendiente(reporte);
      return false;
    }

    try {
      await _reportes.crear(reporte);
      return true;
    } on FalloRed {
      if (_offline == null || reporte.evidencias.isNotEmpty) {
        rethrow;
      }

      await _offline.guardarReportePendiente(reporte);
      return false;
    }
  }
}

/// Aprobar el trabajo y cerrar la orden.
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

/// Devolver el trabajo para correcciones.
class DevolverOrden {
  final OrdenRepositorio _ordenes;

  const DevolverOrden(this._ordenes);

  Future<void> ejecutar({
    required String ordenId,
    required String observaciones,
  }) =>
      _ordenes.devolver(
        ordenId: ordenId,
        observaciones: observaciones,
      );
}
