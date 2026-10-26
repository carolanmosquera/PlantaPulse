// lib/src/core/domain/entities/reporte.dart
import 'evidencia.dart';
import '../utils/formato_fechas.dart';
import 'usuario.dart';

enum EstadoTrabajo { pendiente, enProgreso, bloqueado, resuelto }

extension EstadoTrabajoX on EstadoTrabajo {
  String get etiqueta => switch (this) {
        EstadoTrabajo.pendiente  => 'Pendiente',
        EstadoTrabajo.enProgreso => 'En Progreso',
        EstadoTrabajo.bloqueado  => 'Bloqueado',
        EstadoTrabajo.resuelto   => 'Resuelto',
      };

  String get db => switch (this) {
        EstadoTrabajo.pendiente  => 'pendiente',
        EstadoTrabajo.enProgreso => 'en_progreso',
        EstadoTrabajo.bloqueado  => 'bloqueado',
        EstadoTrabajo.resuelto   => 'resuelto',
      };

  static EstadoTrabajo desdeDb(String? v) => switch (v) {
        'en_progreso' => EstadoTrabajo.enProgreso,
        'bloqueado'   => EstadoTrabajo.bloqueado,
        'resuelto'    => EstadoTrabajo.resuelto,
        _             => EstadoTrabajo.pendiente,
      };
}

/// Un avance publicado por el técnico dentro de una orden (tabla
/// 'reportes', con orden_id). Nunca se consultan fuera de su orden.
///
/// Al insertarse, el servidor actualiza la orden solo (contadores,
/// portada, estado): la app no debe hacerlo.
class Reporte {
  final String id;
  final String ordenId;
  final UsuarioRef autor;

  /// Texto del avance. Se llama 'detalles' y no 'texto' porque un campo con
  /// ese nombre tapa al helper texto() de json_helpers dentro de la clase.
  final String detalles;
  final EstadoTrabajo estadoTrabajo;
  final List<Evidencia> evidencias;   // máximo 30
  final bool esAlertaCritica;
  final bool generadoPorIA;
  final DateTime createdAt;

  const Reporte({
    required this.id,
    required this.ordenId,
    required this.autor,
    required this.detalles,
    this.estadoTrabajo = EstadoTrabajo.enProgreso,
    this.evidencias = const [],
    this.esAlertaCritica = false,
    this.generadoPorIA = false,
    required this.createdAt,
  });

  String get horaTexto => horaAmPm(createdAt);

  /// RUTA de la primera foto (no una URL). La portada de la orden la fija
  /// el servidor al publicar; esto es solo para la UI.
  String? get portada => evidencias.isEmpty ? null : evidencias.first.ruta;
}
