// lib/src/core/domain/repositories/ia_repositorio.dart
import '../entities/borrador_orden_ia.dart';
import '../entities/orden.dart';
import '../entities/progreso_orden_ia.dart';
import '../entities/reporte.dart';
import '../entities/resumen_turno.dart';

/// El asistente de IA. Cada llamada gasta cuota: nadie reintenta por su
/// cuenta, y un fallo llega como FalloApp con un mensaje para mostrar.
abstract class IaRepositorio {
  /// Convierte la nota informal del supervisor en un borrador de orden.
  Future<BorradorOrdenIa> estructurarNota(String nota);

  /// Redacta un reporte a partir de las notas sueltas del técnico.
  Future<String> redactarReporte({
    required String notas,
    required String equipo,
  });

  /// Interpreta las cifras del turno. Las cifras las calcula otra parte de
  /// la app (KAN-66); el asistente solo las lee.
  Future<ResumenTurno> resumirTurno(Map<String, int> cifras);

  /// Estima cuánto lleva la orden y qué podría faltar, leyendo sus
  /// reportes. Orientativo: no se guarda ni cambia la orden.
  Future<ProgresoOrdenIa> calcularProgreso({
    required Orden orden,
    required List<Reporte> reportes,
  });
}
