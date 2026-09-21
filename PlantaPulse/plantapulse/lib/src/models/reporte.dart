// lib/src/models/reporte.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'evidencia.dart';
import 'firestore_helpers.dart';
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

/// Un avance publicado por el técnico dentro de una orden.
/// Vive en la SUBCOLECCIÓN ordenes/{ordenId}/reportes/{reporteId},
/// porque nunca se consultan reportes fuera del contexto de su orden.
class Reporte {
  final String id;
  final String ordenId;
  final UsuarioRef autor;

  /// Texto del avance. Se llama 'detalles' y no 'texto' porque un campo con
  /// ese nombre tapa al helper texto() de firestore_helpers dentro de la clase.
  final String detalles;
  final EstadoTrabajo estadoTrabajo;
  final List<Evidencia> evidencias;   // máximo 4
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

  factory Reporte.desdeFirestore(DocumentSnapshot doc) {
    final d = mapa(doc.data());
    return Reporte(
      id: doc.id,
      ordenId: texto(d['ordenId']),
      autor: UsuarioRef.desdeMapa(mapa(d['autor'])),
      detalles: texto(d['texto']),
      estadoTrabajo: EstadoTrabajoX.desdeDb(d['estadoTrabajo']),
      evidencias:
          listaMapas(d['evidencias']).map(Evidencia.desdeMapa).toList(),
      esAlertaCritica: booleano(d['esAlertaCritica']),
      generadoPorIA: booleano(d['generadoPorIA']),
      createdAt: fecha(d['createdAt']),
    );
  }

  Map<String, dynamic> aFirestore() => {
        'ordenId': ordenId,
        'autor': autor.aMapa(),
        'texto': detalles,
        'estadoTrabajo': estadoTrabajo.db,
        'evidencias': evidencias.map((e) => e.aMapa()).toList(),
        'esAlertaCritica': esAlertaCritica,
        'generadoPorIA': generadoPorIA,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  String get horaTexto => horaAmPm(createdAt);

  /// URL de la primera foto, para la portada de la orden
  String? get portada => evidencias.isEmpty ? null : evidencias.first.thumbUrl;
}