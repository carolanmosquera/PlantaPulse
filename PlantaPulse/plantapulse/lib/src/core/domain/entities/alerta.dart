// lib/src/core/domain/entities/alerta.dart
import '../utils/formato_fechas.dart';

/// OJO con el nombre: esta clase es lo que tu pantalla de Alertas muestra,
/// pero en la base de datos vive en usuarios/{uid}/notificaciones.
/// Son avisos personales, no la alerta de emergencia (ver AlertaCritica).
enum TipoAlerta { critica, preventiva, completada, info }

extension TipoAlertaX on TipoAlerta {

  String get db => name;

  static TipoAlerta desdeDb(String? v) => TipoAlerta.values.firstWhere(
        (t) => t.name == v,
        orElse: () => TipoAlerta.info,
      );
}

class Alerta {
  final String id;
  final TipoAlerta tipo;
  final String titulo;
  final String descripcion;
  final String? codigo;      // "OT-8842"
  final String? ordenId;     // para navegar al tocarla
  final bool noLeida;
  final DateTime createdAt;

  const Alerta({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    this.codigo,
    this.ordenId,
    this.noLeida = true,
    required this.createdAt,
  });

  // Antes 'hora' y 'grupo' eran campos de texto fijos.
  // Ahora se calculan a partir de createdAt, así nunca quedan desactualizados.
  String get hora => horaAmPm(createdAt);
  String get grupo => grupoRelativo(createdAt);
}

// ─────────────────────────────────────────────────────────────
// ALERTA CRÍTICA — la pantalla de Reporte de Emergencia
// Colección raíz 'alertas'. Es un evento de seguridad de la planta,
// no un aviso personal.
// ─────────────────────────────────────────────────────────────

enum TipoEmergencia { fuego, electrico, fuga, mecanico }

extension TipoEmergenciaX on TipoEmergencia {
  String get etiqueta => switch (this) {
        TipoEmergencia.fuego     => 'Fuego / Incendio',
        TipoEmergencia.electrico => 'Falla Eléctrica',
        TipoEmergencia.fuga      => 'Fuga de Líquidos',
        TipoEmergencia.mecanico  => 'Falla Mecánica',
      };

  String get db => name;

  static TipoEmergencia desdeDb(String? v) => TipoEmergencia.values.firstWhere(
        (t) => t.name == v,
        orElse: () => TipoEmergencia.mecanico,
      );
}

enum EstadoAlerta { abierta, atendida, cerrada }

extension EstadoAlertaX on EstadoAlerta {
  String get etiqueta => switch (this) {
        EstadoAlerta.abierta  => 'ABIERTA',
        EstadoAlerta.atendida => 'ATENDIDA',
        EstadoAlerta.cerrada  => 'CERRADA',
      };

  String get db => name;

  static EstadoAlerta desdeDb(String? v) => EstadoAlerta.values.firstWhere(
        (e) => e.name == v,
        orElse: () => EstadoAlerta.abierta,
      );
}