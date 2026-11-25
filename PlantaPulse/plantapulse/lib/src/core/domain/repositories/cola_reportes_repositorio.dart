// lib/src/core/domain/repositories/cola_reportes_repositorio.dart
import '../entities/reporte.dart';

/// Reportes que no se pudieron enviar por falta de conexión (KAN-98).
/// Quedan guardados en el teléfono, por usuario, hasta que se envían:
/// así un reporte escrito en una zona sin señal no se pierde.
abstract class ColaReportesRepositorio {
  /// Id propio para un reporte que todavía no se envió. Se fija ANTES del
  /// primer intento: si un envío llega al servidor pero la respuesta se
  /// pierde, el reintento choca con ese mismo id y no se duplica.
  String nuevoId();

  /// Guarda el reporte (ya con su id) en la cola del autor.
  Future<void> guardar(Reporte reporte);

  /// Los pendientes del usuario, del más viejo al más nuevo.
  Future<List<Reporte>> pendientes(String autorUid);

  /// Lo saca de la cola: ya se envió o el servidor lo rechazó.
  Future<void> quitar(String autorUid, String reporteId);
}
