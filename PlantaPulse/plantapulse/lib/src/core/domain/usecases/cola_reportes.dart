// lib/src/core/domain/usecases/cola_reportes.dart
// KAN-98 · reportes sin conexión. Viven en core porque los usan el
// reporte (feature reportes) y el aviso de pendientes del feed (feature
// ordenes), y un feature no importa a otro.
import '../entities/reporte.dart';
import '../repositories/cola_reportes_repositorio.dart';
import '../repositories/reporte_repositorio.dart';
import '../../errors/fallos.dart';

/// Qué pasó al intentar enviar la cola.
class ResultadoSincronizacion {
  /// Llegaron al servidor (incluye los que ya habían llegado antes).
  final int enviados;

  /// El servidor los rechazó (p. ej. la orden fue invalidada o eliminada):
  /// reintentarlos no sirve, así que salen de la cola. Uno por reporte.
  final List<String> rechazados;

  /// Siguen en el teléfono: no hay conexión todavía.
  final int pendientes;

  const ResultadoSincronizacion({
    this.enviados = 0,
    this.rechazados = const [],
    this.pendientes = 0,
  });
}

/// Envía, en orden, los reportes que quedaron en el teléfono.
///
/// - Sin conexión: se detiene y conserva el resto para el próximo intento.
/// - Ya existía en el servidor (el envío anterior sí llegó): sale de la
///   cola sin duplicarse.
/// - Rechazado por el servidor: sale de la cola y se informa el motivo,
///   para que un reporte imposible no trabe a los demás.
class SincronizarReportesPendientes {
  final ReporteRepositorio _reportes;
  final ColaReportesRepositorio _cola;

  const SincronizarReportesPendientes(this._reportes, this._cola);

  Future<ResultadoSincronizacion> ejecutar(String autorUid) async {
    final cola = await _cola.pendientes(autorUid);
    var enviados = 0;
    final rechazados = <String>[];
    var restantes = cola.length;

    for (final reporte in cola) {
      try {
        await _reportes.crear(reporte);
        enviados++;
      } on FalloDuplicado {
        enviados++;                       // ya había llegado
      } on FalloRed {
        break;                            // sigue sin conexión
      } on FalloApp catch (e) {
        rechazados.add(e.mensaje);        // reintentar no lo arregla
      } catch (_) {
        break;                            // inesperado: no se toca la cola
      }
      await _cola.quitar(autorUid, reporte.id);
      restantes--;
    }

    return ResultadoSincronizacion(
      enviados: enviados,
      rechazados: rechazados,
      pendientes: restantes,
    );
  }
}

/// Cuántos reportes del usuario esperan conexión.
class ContarReportesPendientes {
  final ColaReportesRepositorio _cola;

  const ContarReportesPendientes(this._cola);

  Future<int> ejecutar(String autorUid) async =>
      (await _cola.pendientes(autorUid)).length;
}

/// El mismo reporte con el id que se le fija antes de enviarlo.
Reporte reporteConId(Reporte r, String id) => Reporte(
      id: id,
      ordenId: r.ordenId,
      autor: r.autor,
      detalles: r.detalles,
      estadoTrabajo: r.estadoTrabajo,
      evidencias: r.evidencias,
      esAlertaCritica: r.esAlertaCritica,
      generadoPorIA: r.generadoPorIA,
      createdAt: r.createdAt,
    );
