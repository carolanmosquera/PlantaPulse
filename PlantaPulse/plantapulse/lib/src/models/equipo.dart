// lib/src/models/equipo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

enum EstadoEquipo { operativo, enMantenimiento, fueraDeServicio }

extension EstadoEquipoX on EstadoEquipo {
  String get etiqueta => switch (this) {
        EstadoEquipo.operativo        => 'OPERATIVO',
        EstadoEquipo.enMantenimiento  => 'EN MANTENIMIENTO',
        EstadoEquipo.fueraDeServicio  => 'FUERA DE SERVICIO',
      };

  String get db => switch (this) {
        EstadoEquipo.operativo        => 'operativo',
        EstadoEquipo.enMantenimiento  => 'en_mantenimiento',
        EstadoEquipo.fueraDeServicio  => 'fuera_de_servicio',
      };

  static EstadoEquipo desdeDb(String? v) => switch (v) {
        'en_mantenimiento'  => EstadoEquipo.enMantenimiento,
        'fuera_de_servicio' => EstadoEquipo.fueraDeServicio,
        _                   => EstadoEquipo.operativo,
      };
}

class Equipo {
  final String id;
  final String plantaId;
  final String zonaId;
  final String zonaNombre;        // denormalizado
  final String nombre;            // "Compresor Atlas Copco GA75"
  final String serial;            // "AC-88291-K"
  final String modelo;            // "2022"
  final String tipo;              // mecánico, eléctrico, hidráulico
  final String? fotoUrl;
  final EstadoEquipo estado;
  final DateTime? ultimoMantenimiento;   // denormalizado al cerrar una orden
  final bool activo;

  const Equipo({
    required this.id,
    required this.plantaId,
    this.zonaId = '',
    this.zonaNombre = '',
    required this.nombre,
    this.serial = '',
    this.modelo = '',
    this.tipo = '',
    this.fotoUrl,
    this.estado = EstadoEquipo.operativo,
    this.ultimoMantenimiento,
    this.activo = true,
  });

  factory Equipo.desdeFirestore(DocumentSnapshot doc) {
    final d = mapa(doc.data());
    return Equipo(
      id: doc.id,
      plantaId: texto(d['plantaId']),
      zonaId: texto(d['zonaId']),
      zonaNombre: texto(d['zonaNombre']),
      nombre: texto(d['nombre'], 'Sin equipo'),
      serial: texto(d['serial']),
      modelo: texto(d['modelo']),
      tipo: texto(d['tipo']),
      fotoUrl: textoOpcional(d['fotoUrl']),
      estado: EstadoEquipoX.desdeDb(d['estado']),
      ultimoMantenimiento: fechaOpcional(d['ultimoMantenimiento']),
      activo: booleano(d['activo'], true),
    );
  }

  Map<String, dynamic> aFirestore() => {
        'plantaId': plantaId,
        'zonaId': zonaId,
        'zonaNombre': zonaNombre,
        'nombre': nombre,
        'serial': serial,
        'modelo': modelo,
        'tipo': tipo,
        'fotoUrl': fotoUrl,
        'estado': estado.db,
        'ultimoMantenimiento': ultimoMantenimiento == null
            ? null
            : Timestamp.fromDate(ultimoMantenimiento!),
        'activo': activo,
      };

  /// Texto que ya usa tu pantalla de detalle: "Serial: AC-88291-K / Mod: 2022"
  String get subtitulo => 'Serial: $serial / Mod: $modelo';
}