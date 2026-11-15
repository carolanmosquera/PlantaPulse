// lib/src/core/domain/entities/progreso_orden_ia.dart

/// Estimación del avance de una orden hecha por el asistente a partir de
/// sus reportes. Es ORIENTATIVA: la pantalla lo dice, y no se guarda en la
/// base ni cambia el estado de la orden.
class ProgresoOrdenIa {
  /// 0 a 100. Una sugerencia, no una medición.
  final int porcentaje;

  /// Lo que ya se hizo, según los reportes.
  final String resumen;

  /// Lo que podría faltar y, si se puede, cuánto tiempo aproximado.
  final String falta;

  const ProgresoOrdenIa({
    required this.porcentaje,
    required this.resumen,
    required this.falta,
  });
}
