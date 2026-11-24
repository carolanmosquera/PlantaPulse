// lib/src/core/domain/usecases/ia.dart
// Casos de uso del asistente. Viven en core porque los usan crear_orden,
// reportes y (cuando lleguen las cifras) el resumen de turno.
import '../entities/borrador_orden_ia.dart';
import '../entities/orden.dart';
import '../entities/progreso_orden_ia.dart';
import '../entities/reporte.dart';
import '../entities/resumen_turno.dart';
import '../repositories/ia_repositorio.dart';

/// KAN-92: la nota del supervisor, estructurada como orden.
class EstructurarNota {
  final IaRepositorio _ia;

  const EstructurarNota(this._ia);

  Future<BorradorOrdenIa> ejecutar(String nota) =>
      _ia.estructurarNota(nota.trim());
}

/// KAN-93: las notas sueltas del técnico, redactadas como reporte.
class RedactarReporte {
  final IaRepositorio _ia;

  const RedactarReporte(this._ia);

  Future<String> ejecutar({required String notas, required String equipo}) =>
      _ia.redactarReporte(notas: notas.trim(), equipo: equipo.trim());
}

/// "Calcular progreso" del supervisor: una estimación orientativa del
/// avance de la orden a partir de sus reportes. Sin reportes no hay nada
/// que estimar, y no se llama (no se gasta cuota).
class CalcularProgreso {
  final IaRepositorio _ia;

  const CalcularProgreso(this._ia);

  Future<ProgresoOrdenIa> ejecutar({
    required Orden orden,
    required List<Reporte> reportes,
  }) =>
      _ia.calcularProgreso(orden: orden, reportes: reportes);
}

/// KAN-94: queda listo para conectar cuando existan las cifras del turno
/// (KAN-66). No las calcula: las recibe.
class ResumirTurno {
  final IaRepositorio _ia;

  const ResumirTurno(this._ia);

  Future<ResumenTurno> ejecutar(Map<String, int> cifras) =>
      _ia.resumirTurno(cifras);
}
