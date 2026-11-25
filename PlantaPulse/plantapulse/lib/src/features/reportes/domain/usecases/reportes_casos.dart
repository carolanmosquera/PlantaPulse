// lib/src/features/reportes/domain/usecases/reportes_casos.dart
// Casos de uso del ciclo del reporte: el técnico documenta, el supervisor
// valida y cierra (o devuelve). SubirEvidencia vive en core
// (core/domain/usecases/evidencias.dart): crear orden también sube fotos.
import '../../../../core/domain/entities/reporte.dart';
import '../../../../core/domain/repositories/cola_reportes_repositorio.dart';
import '../../../../core/domain/usecases/cola_reportes.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';
import '../../../../core/domain/repositories/reporte_repositorio.dart';
import '../../../../core/errors/fallos.dart';

/// Cómo terminó "ENVIAR REPORTE".
enum ResultadoPublicacion {
  /// Llegó al servidor.
  publicado,

  /// No había conexión: quedó guardado en el teléfono y se envía solo
  /// cuando vuelva la señal (KAN-98).
  enCola,
}

/// Inserta el reporte con las rutas ya subidas. La orden NO se toca: el
/// servidor la actualiza solo y el cambio vuelve por el stream.
///
/// Con [cola] (la app real), un fallo de red no pierde el reporte: queda
/// guardado en el teléfono. Sin cola se comporta como antes.
class PublicarReporte {
  final ReporteRepositorio _reportes;
  final ColaReportesRepositorio? _cola;

  const PublicarReporte(this._reportes, {this._cola});

  Future<ResultadoPublicacion> ejecutar(Reporte reporte) async {
    final cola = _cola;
    if (cola == null) {
      await _reportes.crear(reporte);
      return ResultadoPublicacion.publicado;
    }

    // El id se fija antes del primer intento: si este envío llega pero la
    // respuesta se pierde, el reintento desde la cola no lo duplica
    final conId =
        reporte.id.isEmpty ? reporteConId(reporte, cola.nuevoId()) : reporte;
    try {
      await _reportes.crear(conId);
      return ResultadoPublicacion.publicado;
    } on FalloRed {
      try {
        await cola.guardar(conId);
      } catch (_) {
        throw const FalloApp(
            'Sin conexión, y no se pudo guardar el reporte en el teléfono. '
            'Intenta de nuevo.');
      }
      return ResultadoPublicacion.enCola;
    }
  }
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
