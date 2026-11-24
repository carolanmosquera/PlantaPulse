// lib/src/core/domain/entities/borrador_orden_ia.dart
import 'orden.dart';

/// Lo que el asistente propone a partir de la nota del supervisor. Es una
/// propuesta: el supervisor la revisa y la corrige en el paso 2 antes de
/// publicar.
class BorradorOrdenIa {
  final String titulo;
  final String descripcion;

  /// Texto libre: puede no existir en las categorías de la planta. El
  /// asistente NO la crea; si no existe, el supervisor decide.
  final String categoriaSugerida;

  /// Nunca [Prioridad.critica]: marcar una orden como crítica es una
  /// decisión humana, no del modelo.
  final Prioridad prioridadSugerida;

  const BorradorOrdenIa({
    required this.titulo,
    required this.descripcion,
    required this.categoriaSugerida,
    required this.prioridadSugerida,
  });
}
