// lib/src/core/domain/entities/orden.dart
import '../utils/formato_fechas.dart';
import 'evidencia.dart';
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
  /// Nombre de la categoría tal como estaba el día que se creó la orden.
  /// Es texto y no un id a propósito: si alguien renombra la categoría,
  /// el historial conserva el nombre original.
  final String categoria;

  // Ubicación (denormalizada: el feed la muestra sin consulta extra)
  final String zonaId;
  final String zonaNombre;
  final String? equipoId;
  final String? equipoNombre;

  // Personas (denormalizadas)
  final UsuarioRef creadoPor;
  /// null = orden sin asignar. No es un estado del trabajo: una orden
  /// sin responsable puede estar en cualquier estado.
  final UsuarioRef? asignadoA;
  final String? asignadoAUid;      // copia plana, para poder filtrar por columna

  // Estado
  final EstadoOrden estado;
  final Prioridad prioridad;

  // Fechas
  final DateTime createdAt;
  final DateTime fechaLimite;
  final DateTime? fechaCierre;
  final DateTime ultimaActividad;  // la IA busca órdenes estancadas por aquí

  // Visual y contadores (denormalizados)
  /// RUTA de la foto de portada (no una URL). La fija el servidor con la
  /// última foto de cada reporte; al crear la orden, la app pone la última
  /// foto del hallazgo.
  final String? portadaUrl;
  final int totalReportes;
  final int totalAlertas;

  // IA
  final bool generadaPorIA;
  final String? notaOriginal;      // lo que dictó el supervisor antes de estructurar

  /// Fotos del hallazgo, tomadas al crear la orden (máximo 30). Las del
  /// trabajo van en cada reporte.
  final List<Evidencia> evidencias;

  // Cierre
  final UsuarioRef? validadaPor;
  final String? observacionesSupervisor;

  /// Eliminación lógica: la fila sigue en la base (es historial), pero la
  /// app ya no la muestra. Solo la pone la función eliminar_orden().
  final DateTime? eliminadaEn;

  const Orden({
    required this.id,
    required this.codigo,
    required this.plantaId,
    required this.titulo,
    this.descripcion = '',
    this.categoria = '',
    this.zonaId = '',
    this.zonaNombre = '',
    this.equipoId,
    this.equipoNombre,
    required this.creadoPor,
    this.asignadoA,
    this.asignadoAUid,
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
    this.evidencias = const [],
    this.validadaPor,
    this.observacionesSupervisor,
    this.eliminadaEn,
  });

  // ── Getters para la UI que ya tienes ──────────────────────
  // Así tus pantallas siguen leyendo 'ubicacion', 'hora' y 'prioridadTexto'
  // sin que tengas que reescribirlas.

  String get ubicacion => zonaNombre;

  String get hora => fechaCorta(fechaLimite);

  String get horaCreacion => horaAmPm(createdAt);

  String get prioridadTexto => prioridad.etiqueta;

  bool get sinAsignar => asignadoAUid == null;

  bool get eliminada => eliminadaEn != null;

  /// Lo mismo que exige eliminar_orden() en la base, para no ofrecer la
  /// opción cuando ya se sabe que va a fallar. Reportes, alertas y
  /// novedades vinculadas solo los puede comprobar el servidor.
  bool get puedeEliminarse => !eliminada && estado == EstadoOrden.pendiente;

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
        asignadoAUid: (asignadoA ?? this.asignadoA)?.uid,
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
        evidencias: evidencias,
        validadaPor: validadaPor ?? this.validadaPor,
        observacionesSupervisor:
            observacionesSupervisor ?? this.observacionesSupervisor,
        eliminadaEn: eliminadaEn,
      );
}
