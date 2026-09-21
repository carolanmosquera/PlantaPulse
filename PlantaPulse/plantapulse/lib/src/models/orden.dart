// lib/src/models/orden.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'firestore_helpers.dart';
import 'usuario.dart';

// ─────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────

enum EstadoOrden { pendiente, enProgreso, critica, validando, completada }

extension EstadoOrdenX on EstadoOrden {
  String get etiqueta => switch (this) {
        EstadoOrden.pendiente  => 'PENDIENTE',
        EstadoOrden.enProgreso => 'EN PROGRESO',
        EstadoOrden.critica    => 'CRÍTICA',
        EstadoOrden.validando  => 'VALIDANDO',
        EstadoOrden.completada => 'COMPLETADA',
      };

  Color get color => switch (this) {
        EstadoOrden.pendiente  => AppColors.gris,
        EstadoOrden.enProgreso => AppColors.ambar,
        EstadoOrden.critica    => AppColors.rojo,
        EstadoOrden.validando  => AppColors.verde,
        EstadoOrden.completada => AppColors.verde,
      };

  String get db => switch (this) {
        EstadoOrden.pendiente  => 'pendiente',
        EstadoOrden.enProgreso => 'en_progreso',
        EstadoOrden.critica    => 'critica',
        EstadoOrden.validando  => 'validando',
        EstadoOrden.completada => 'completada',
      };

  static EstadoOrden desdeDb(String? v) => switch (v) {
        'en_progreso' => EstadoOrden.enProgreso,
        'critica'     => EstadoOrden.critica,
        'validando'   => EstadoOrden.validando,
        'completada'  => EstadoOrden.completada,
        _             => EstadoOrden.pendiente,
      };

  /// La orden sigue abierta: sirve para filtrar "mis tareas"
  bool get estaAbierta => this != EstadoOrden.completada;
}

enum Prioridad { baja, media, alta, critica }

extension PrioridadX on Prioridad {
  String get etiqueta => switch (this) {
        Prioridad.baja    => 'Baja',
        Prioridad.media   => 'Media',
        Prioridad.alta    => 'Alta',
        Prioridad.critica => 'Urgente',
      };

  Color get color => switch (this) {
        Prioridad.baja    => AppColors.gris,
        Prioridad.media   => AppColors.ambar,
        Prioridad.alta    => AppColors.naranja,
        Prioridad.critica => AppColors.rojo,
      };

  String get db => switch (this) {
        Prioridad.baja    => 'baja',
        Prioridad.media   => 'media',
        Prioridad.alta    => 'alta',
        Prioridad.critica => 'critica',
      };

  static Prioridad desdeDb(String? v) => switch (v) {
        'baja'    => Prioridad.baja,
        'alta'    => Prioridad.alta,
        'critica' => Prioridad.critica,
        _         => Prioridad.media,
      };
}

enum CategoriaOrden { mecanico, electrico, hidraulico, inspeccion, critico }

extension CategoriaOrdenX on CategoriaOrden {
  String get etiqueta => switch (this) {
        CategoriaOrden.mecanico   => 'Mecánico',
        CategoriaOrden.electrico  => 'Eléctrico',
        CategoriaOrden.hidraulico => 'Hidráulico',
        CategoriaOrden.inspeccion => 'Inspección',
        CategoriaOrden.critico    => 'Crítico',
      };

  IconData get icono => switch (this) {
        CategoriaOrden.mecanico   => Icons.build_outlined,
        CategoriaOrden.electrico  => Icons.bolt,
        CategoriaOrden.hidraulico => Icons.water_drop_outlined,
        CategoriaOrden.inspeccion => Icons.search,
        CategoriaOrden.critico    => Icons.warning_amber_rounded,
      };

  String get db => name;   // 'mecanico', 'electrico', ...

  static CategoriaOrden desdeDb(String? v) => CategoriaOrden.values.firstWhere(
        (c) => c.name == v,
        orElse: () => CategoriaOrden.mecanico,
      );
}

// ─────────────────────────────────────────────────────────────
// ORDEN — el "post" del feed
// ─────────────────────────────────────────────────────────────

class Orden {
  final String id;
  final String codigo;          // "WO-2026-0892", legible para el personal
  final String plantaId;

  // Contenido
  final String titulo;
  final String descripcion;
  final CategoriaOrden categoria;

  // Ubicación (denormalizada: el feed la muestra sin consulta extra)
  final String zonaId;
  final String zonaNombre;
  final String? equipoId;
  final String? equipoNombre;

  // Personas (denormalizadas)
  final UsuarioRef creadoPor;
  final UsuarioRef asignadoA;      // NUNCA null: toda orden tiene responsable
  final String asignadoAUid;       // copia plana, para poder filtrar en Firestore

  // Estado
  final EstadoOrden estado;
  final Prioridad prioridad;

  // Fechas
  final DateTime createdAt;
  final DateTime fechaLimite;
  final DateTime? fechaCierre;
  final DateTime ultimaActividad;  // la IA busca órdenes estancadas por aquí

  // Visual y contadores (denormalizados)
  final String? portadaUrl;
  final int totalReportes;
  final int totalAlertas;

  // IA
  final bool generadaPorIA;
  final String? notaOriginal;      // lo que dictó el supervisor antes de estructurar

  // Cierre
  final UsuarioRef? validadaPor;
  final String? observacionesSupervisor;

  const Orden({
    required this.id,
    required this.codigo,
    required this.plantaId,
    required this.titulo,
    this.descripcion = '',
    this.categoria = CategoriaOrden.mecanico,
    this.zonaId = '',
    this.zonaNombre = '',
    this.equipoId,
    this.equipoNombre,
    required this.creadoPor,
    required this.asignadoA,
    required this.asignadoAUid,
    this.estado = EstadoOrden.pendiente,
    this.prioridad = Prioridad.media,
    required this.createdAt,
    required this.fechaLimite,
    this.fechaCierre,
    required this.ultimaActividad,
    this.portadaUrl,
    this.totalReportes = 0,
    this.totalAlertas = 0,
    this.generadaPorIA = false,
    this.notaOriginal,
    this.validadaPor,
    this.observacionesSupervisor,
  });

  factory Orden.desdeFirestore(DocumentSnapshot doc) {
    final d = mapa(doc.data());
    final asignado = UsuarioRef.desdeMapa(mapa(d['asignadoA']));
    return Orden(
      id: doc.id,
      codigo: texto(d['codigo'], doc.id),
      plantaId: texto(d['plantaId']),
      titulo: texto(d['titulo'], 'Sin título'),
      descripcion: texto(d['descripcion']),
      categoria: CategoriaOrdenX.desdeDb(d['categoria']),
      zonaId: texto(d['zonaId']),
      zonaNombre: texto(d['zonaNombre']),
      equipoId: textoOpcional(d['equipoId']),
      equipoNombre: textoOpcional(d['equipoNombre']),
      creadoPor: UsuarioRef.desdeMapa(mapa(d['creadoPor'])),
      asignadoA: asignado,
      asignadoAUid: texto(d['asignadoAUid'], asignado.uid),
      estado: EstadoOrdenX.desdeDb(d['estado']),
      prioridad: PrioridadX.desdeDb(d['prioridad']),
      createdAt: fecha(d['createdAt']),
      fechaLimite: fecha(d['fechaLimite']),
      fechaCierre: fechaOpcional(d['fechaCierre']),
      ultimaActividad: fecha(d['ultimaActividad']),
      portadaUrl: textoOpcional(d['portadaUrl']),
      totalReportes: entero(d['totalReportes']),
      totalAlertas: entero(d['totalAlertas']),
      generadaPorIA: booleano(d['generadaPorIA']),
      notaOriginal: textoOpcional(d['notaOriginal']),
      validadaPor: d['validadaPor'] == null
          ? null
          : UsuarioRef.desdeMapa(mapa(d['validadaPor'])),
      observacionesSupervisor: textoOpcional(d['observacionesSupervisor']),
    );
  }

  Map<String, dynamic> aFirestore() => {
        'codigo': codigo,
        'plantaId': plantaId,
        'titulo': titulo,
        'descripcion': descripcion,
        'categoria': categoria.db,
        'zonaId': zonaId,
        'zonaNombre': zonaNombre,
        'equipoId': equipoId,
        'equipoNombre': equipoNombre,
        'creadoPor': creadoPor.aMapa(),
        'asignadoA': asignadoA.aMapa(),
        'asignadoAUid': asignadoAUid,
        'estado': estado.db,
        'prioridad': prioridad.db,
        'createdAt': Timestamp.fromDate(createdAt),
        'fechaLimite': Timestamp.fromDate(fechaLimite),
        'fechaCierre':
            fechaCierre == null ? null : Timestamp.fromDate(fechaCierre!),
        'ultimaActividad': Timestamp.fromDate(ultimaActividad),
        'portadaUrl': portadaUrl,
        'totalReportes': totalReportes,
        'totalAlertas': totalAlertas,
        'generadaPorIA': generadaPorIA,
        'notaOriginal': notaOriginal,
        'validadaPor': validadaPor?.aMapa(),
        'observacionesSupervisor': observacionesSupervisor,
      };

  // ── Getters para la UI que ya tienes ──────────────────────
  // Así tus pantallas siguen leyendo 'ubicacion', 'hora' y 'prioridadTexto'
  // sin que tengas que reescribirlas.

  String get ubicacion => zonaNombre;

  String get hora => fechaCorta(fechaLimite);

  String get horaCreacion => horaAmPm(createdAt);

  String get prioridadTexto => prioridad.etiqueta;

  bool get estaVencida =>
      estado.estaAbierta && fechaLimite.isBefore(DateTime.now());

  /// Cuánto falta para vencer: "15 min", "1h 20m", "Vencida"
  String get tiempoRestante {
    if (!estado.estaAbierta) return '—';
    final falta = fechaLimite.difference(DateTime.now());
    if (falta.isNegative) return 'Vencida';
    if (falta.inHours == 0) return '${falta.inMinutes} min';
    return '${falta.inHours}h ${falta.inMinutes % 60}m';
  }

  Orden copyWith({
    String? titulo,
    String? descripcion,
    EstadoOrden? estado,
    Prioridad? prioridad,
    UsuarioRef? asignadoA,
    DateTime? fechaLimite,
    DateTime? fechaCierre,
    DateTime? ultimaActividad,
    String? portadaUrl,
    int? totalReportes,
    int? totalAlertas,
    UsuarioRef? validadaPor,
    String? observacionesSupervisor,
  }) =>
      Orden(
        id: id,
        codigo: codigo,
        plantaId: plantaId,
        titulo: titulo ?? this.titulo,
        descripcion: descripcion ?? this.descripcion,
        categoria: categoria,
        zonaId: zonaId,
        zonaNombre: zonaNombre,
        equipoId: equipoId,
        equipoNombre: equipoNombre,
        creadoPor: creadoPor,
        asignadoA: asignadoA ?? this.asignadoA,
        asignadoAUid: (asignadoA ?? this.asignadoA).uid,
        estado: estado ?? this.estado,
        prioridad: prioridad ?? this.prioridad,
        createdAt: createdAt,
        fechaLimite: fechaLimite ?? this.fechaLimite,
        fechaCierre: fechaCierre ?? this.fechaCierre,
        ultimaActividad: ultimaActividad ?? this.ultimaActividad,
        portadaUrl: portadaUrl ?? this.portadaUrl,
        totalReportes: totalReportes ?? this.totalReportes,
        totalAlertas: totalAlertas ?? this.totalAlertas,
        generadaPorIA: generadaPorIA,
        notaOriginal: notaOriginal,
        validadaPor: validadaPor ?? this.validadaPor,
        observacionesSupervisor:
            observacionesSupervisor ?? this.observacionesSupervisor,
      );
}