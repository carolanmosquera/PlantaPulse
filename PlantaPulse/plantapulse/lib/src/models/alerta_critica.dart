// lib/src/models/alerta_critica.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alerta.dart';
import 'evidencia.dart';
import 'firestore_helpers.dart';
import 'usuario.dart';

/// Evento de seguridad reportado desde la pantalla de Emergencia.
/// Colección raíz 'alertas': debe verse aunque no venga de ninguna orden.
class AlertaCritica {
  final String id;
  final String plantaId;
  final String zonaId;
  final String zonaNombre;
  final String? ordenId;          // opcional: puede no venir de una orden
  final TipoEmergencia tipo;
  final String descripcion;
  final UsuarioRef creadoPor;
  final GeoPoint? ubicacionGps;
  final List<Evidencia> evidencias;
  final EstadoAlerta estado;
  final DateTime createdAt;

  const AlertaCritica({
    required this.id,
    required this.plantaId,
    this.zonaId = '',
    this.zonaNombre = '',
    this.ordenId,
    required this.tipo,
    required this.descripcion,
    required this.creadoPor,
    this.ubicacionGps,
    this.evidencias = const [],
    this.estado = EstadoAlerta.abierta,
    required this.createdAt,
  });

  factory AlertaCritica.desdeFirestore(DocumentSnapshot doc) {
    final d = mapa(doc.data());
    return AlertaCritica(
      id: doc.id,
      plantaId: texto(d['plantaId']),
      zonaId: texto(d['zonaId']),
      zonaNombre: texto(d['zonaNombre']),
      ordenId: textoOpcional(d['ordenId']),
      tipo: TipoEmergenciaX.desdeDb(d['tipo']),
      descripcion: texto(d['descripcion']),
      creadoPor: UsuarioRef.desdeMapa(mapa(d['creadoPor'])),
      ubicacionGps: d['ubicacionGps'] is GeoPoint ? d['ubicacionGps'] : null,
      evidencias:
          listaMapas(d['evidencias']).map(Evidencia.desdeMapa).toList(),
      estado: EstadoAlertaX.desdeDb(d['estado']),
      createdAt: fecha(d['createdAt']),
    );
  }

  Map<String, dynamic> aFirestore() => {
        'plantaId': plantaId,
        'zonaId': zonaId,
        'zonaNombre': zonaNombre,
        'ordenId': ordenId,
        'tipo': tipo.db,
        'descripcion': descripcion,
        'creadoPor': creadoPor.aMapa(),
        'ubicacionGps': ubicacionGps,
        'evidencias': evidencias.map((e) => e.aMapa()).toList(),
        'estado': estado.db,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  String get hora => horaAmPm(createdAt);

  /// "Planta Norte • Sector A-04 (GPS: 19.43, -99.13)"
  String get ubicacionTexto {
    if (ubicacionGps == null) return zonaNombre;
    final lat = ubicacionGps!.latitude.toStringAsFixed(2);
    final lng = ubicacionGps!.longitude.toStringAsFixed(2);
    return '$zonaNombre (GPS: $lat, $lng)';
  }
}