// lib/src/models/novedad.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'evidencia.dart';
import 'firestore_helpers.dart';
import 'usuario.dart';

/// Ciclo de vida de una novedad:
///   reportada  →  revisada  →  convertida (en orden)
///                          ↘  descartada
enum EstadoNovedad { reportada, revisada, convertida, descartada }

extension EstadoNovedadX on EstadoNovedad {
  String get etiqueta => switch (this) {
        EstadoNovedad.reportada  => 'REPORTADA',
        EstadoNovedad.revisada   => 'EN REVISIÓN',
        EstadoNovedad.convertida => 'ORDEN CREADA',
        EstadoNovedad.descartada => 'DESCARTADA',
      };

  Color get color => switch (this) {
        EstadoNovedad.reportada  => AppColors.ambar,
        EstadoNovedad.revisada   => AppColors.azul,
        EstadoNovedad.convertida => AppColors.verde,
        EstadoNovedad.descartada => AppColors.gris,
      };

  String get db => name;

  static EstadoNovedad desdeDb(String? v) => EstadoNovedad.values.firstWhere(
        (e) => e.name == v,
        orElse: () => EstadoNovedad.reportada,
      );

  /// Sigue esperando decisión del supervisor
  bool get pendiente =>
      this == EstadoNovedad.reportada || this == EstadoNovedad.revisada;
}

enum CategoriaNovedad {
  electrica,
  mecanica,
  infraestructura,
  seguridad,
  limpieza,
  otra,
}

extension CategoriaNovedadX on CategoriaNovedad {
  String get etiqueta => switch (this) {
        CategoriaNovedad.electrica       => 'Eléctrica',
        CategoriaNovedad.mecanica        => 'Mecánica',
        CategoriaNovedad.infraestructura => 'Infraestructura',
        CategoriaNovedad.seguridad       => 'Seguridad',
        CategoriaNovedad.limpieza        => 'Limpieza',
        CategoriaNovedad.otra            => 'Otra',
      };

  IconData get icono => switch (this) {
        CategoriaNovedad.electrica       => Icons.lightbulb_outline,
        CategoriaNovedad.mecanica        => Icons.build_outlined,
        CategoriaNovedad.infraestructura => Icons.domain,
        CategoriaNovedad.seguridad       => Icons.health_and_safety_outlined,
        CategoriaNovedad.limpieza        => Icons.cleaning_services_outlined,
        CategoriaNovedad.otra            => Icons.chat_bubble_outline,
      };

  String get db => name;

  static CategoriaNovedad desdeDb(String? v) =>
      CategoriaNovedad.values.firstWhere(
        (c) => c.name == v,
        orElse: () => CategoriaNovedad.otra,
      );
}

/// Una observación de cualquier persona de la planta.
/// "Falla la luz en el cuarto A", "Ventana agrietada en el piso B".
///
/// No es una orden: nadie queda responsable de atenderla.
/// El supervisor la revisa y decide si la convierte en orden.
class Novedad {
  final String id;
  final String plantaId;
  final String zonaId;
  final String zonaNombre;       // denormalizado
  final String descripcion;      // NO se llama 'texto': chocaría con la función texto()
  final CategoriaNovedad categoria;
  final UsuarioRef autor;
  final List<Evidencia> evidencias;   // opcional, máximo 4
  final EstadoNovedad estado;
  final String? ordenId;         // si se convirtió en orden, cuál
  final UsuarioRef? revisadaPor;
  final DateTime? revisadaEn;
  final DateTime createdAt;

  const Novedad({
    required this.id,
    required this.plantaId,
    this.zonaId = '',
    this.zonaNombre = '',
    required this.descripcion,
    this.categoria = CategoriaNovedad.otra,
    required this.autor,
    this.evidencias = const [],
    this.estado = EstadoNovedad.reportada,
    this.ordenId,
    this.revisadaPor,
    this.revisadaEn,
    required this.createdAt,
  });

  factory Novedad.desdeFirestore(DocumentSnapshot doc) {
    final d = mapa(doc.data());
    return Novedad(
      id: doc.id,
      plantaId: texto(d['plantaId']),
      zonaId: texto(d['zonaId']),
      zonaNombre: texto(d['zonaNombre']),
      descripcion: texto(d['descripcion']),
      categoria: CategoriaNovedadX.desdeDb(d['categoria']),
      autor: UsuarioRef.desdeMapa(mapa(d['autor'])),
      evidencias:
          listaMapas(d['evidencias']).map(Evidencia.desdeMapa).toList(),
      estado: EstadoNovedadX.desdeDb(d['estado']),
      ordenId: textoOpcional(d['ordenId']),
      revisadaPor: d['revisadaPor'] == null
          ? null
          : UsuarioRef.desdeMapa(mapa(d['revisadaPor'])),
      revisadaEn: fechaOpcional(d['revisadaEn']),
      createdAt: fecha(d['createdAt']),
    );
  }

  Map<String, dynamic> aFirestore() => {
        'plantaId': plantaId,
        'zonaId': zonaId,
        'zonaNombre': zonaNombre,
        'descripcion': descripcion,
        'categoria': categoria.db,
        'autor': autor.aMapa(),
        'evidencias': evidencias.map((e) => e.aMapa()).toList(),
        'estado': estado.db,
        'ordenId': ordenId,
        'revisadaPor': revisadaPor?.aMapa(),
        'revisadaEn':
            revisadaEn == null ? null : Timestamp.fromDate(revisadaEn!),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  String get hora => horaAmPm(createdAt);
  String get grupo => grupoRelativo(createdAt);

  /// Para pasarle al paso 1 de crear orden cuando el supervisor la convierte
  bool get puedeConvertirse => estado.pendiente;
}