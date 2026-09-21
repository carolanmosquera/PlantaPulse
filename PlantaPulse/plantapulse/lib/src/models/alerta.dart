// lib/src/models/alerta.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'firestore_helpers.dart';

/// OJO con el nombre: esta clase es lo que tu pantalla de Alertas muestra,
/// pero en la base de datos vive en usuarios/{uid}/notificaciones.
/// Son avisos personales, no la alerta de emergencia (ver AlertaCritica).
enum TipoAlerta { critica, preventiva, completada, info }

extension TipoAlertaX on TipoAlerta {
  IconData get icono => switch (this) {
        TipoAlerta.critica    => Icons.warning_amber_rounded,
        TipoAlerta.preventiva => Icons.schedule,
        TipoAlerta.completada => Icons.check_circle_outline,
        TipoAlerta.info       => Icons.info_outline,
      };

  Color get color => switch (this) {
        TipoAlerta.critica    => AppColors.rojo,
        TipoAlerta.preventiva => AppColors.azul,
        TipoAlerta.completada => AppColors.verde,
        TipoAlerta.info       => AppColors.textoGris,
      };

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

  factory Alerta.desdeFirestore(DocumentSnapshot doc) {
    final d = mapa(doc.data());
    return Alerta(
      id: doc.id,
      tipo: TipoAlertaX.desdeDb(d['tipo']),
      titulo: texto(d['titulo']),
      descripcion: texto(d['descripcion']),
      codigo: textoOpcional(d['codigo']),
      ordenId: textoOpcional(d['ordenId']),
      noLeida: !booleano(d['leida']),     // en la base se guarda 'leida'
      createdAt: fecha(d['createdAt']),
    );
  }

  Map<String, dynamic> aFirestore() => {
        'tipo': tipo.db,
        'titulo': titulo,
        'descripcion': descripcion,
        'codigo': codigo,
        'ordenId': ordenId,
        'leida': !noLeida,
        'createdAt': Timestamp.fromDate(createdAt),
      };

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

  IconData get icono => switch (this) {
        TipoEmergencia.fuego     => Icons.local_fire_department_outlined,
        TipoEmergencia.electrico => Icons.bolt,
        TipoEmergencia.fuga      => Icons.water_drop_outlined,
        TipoEmergencia.mecanico  => Icons.build_outlined,
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