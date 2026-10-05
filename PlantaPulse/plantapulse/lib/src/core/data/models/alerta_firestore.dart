// lib/src/core/data/models/alerta_firestore.dart
// TODO fase B: mover a data/models como AlertaModelo y AlertaCriticaModelo.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/alerta.dart';
import '../../domain/entities/alerta_critica.dart';
import '../firestore_helpers.dart';
import 'evidencia_mapa.dart';
import 'usuario_firestore.dart';

Alerta alertaDesdeFirestore(DocumentSnapshot doc) {
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

extension AlertaFirestore on Alerta {
  Map<String, dynamic> aFirestore() => {
        'tipo': tipo.db,
        'titulo': titulo,
        'descripcion': descripcion,
        'codigo': codigo,
        'ordenId': ordenId,
        'leida': !noLeida,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

AlertaCritica alertaCriticaDesdeFirestore(DocumentSnapshot doc) {
  final d = mapa(doc.data());
  final gps = d['ubicacionGps'];
  return AlertaCritica(
    id: doc.id,
    plantaId: texto(d['plantaId']),
    zonaId: texto(d['zonaId']),
    zonaNombre: texto(d['zonaNombre']),
    ordenId: textoOpcional(d['ordenId']),
    tipo: TipoEmergenciaX.desdeDb(d['tipo']),
    descripcion: texto(d['descripcion']),
    creadoPor: usuarioRefDesdeMapa(mapa(d['creadoPor'])),
    ubicacionGps:
        gps is GeoPoint ? PuntoGps(gps.latitude, gps.longitude) : null,
    evidencias: listaMapas(d['evidencias']).map(evidenciaDesdeMapa).toList(),
    estado: EstadoAlertaX.desdeDb(d['estado']),
    createdAt: fecha(d['createdAt']),
  );
}

extension AlertaCriticaFirestore on AlertaCritica {
  Map<String, dynamic> aFirestore() => {
        'plantaId': plantaId,
        'zonaId': zonaId,
        'zonaNombre': zonaNombre,
        'ordenId': ordenId,
        'tipo': tipo.db,
        'descripcion': descripcion,
        'creadoPor': creadoPor.aMapa(),
        'ubicacionGps': ubicacionGps == null
            ? null
            : GeoPoint(ubicacionGps!.latitude, ubicacionGps!.longitude),
        'evidencias': evidencias.map((e) => e.aMapa()).toList(),
        'estado': estado.db,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
