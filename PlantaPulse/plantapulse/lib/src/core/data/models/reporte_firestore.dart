// lib/src/core/data/models/reporte_firestore.dart
// TODO fase B: mover a data/models como ReporteModelo con fromJson/toJson.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reporte.dart';
import '../firestore_helpers.dart';
import 'evidencia_mapa.dart';
import 'usuario_firestore.dart';

Reporte reporteDesdeFirestore(DocumentSnapshot doc) {
  final d = mapa(doc.data());
  return Reporte(
    id: doc.id,
    ordenId: texto(d['ordenId']),
    autor: usuarioRefDesdeMapa(mapa(d['autor'])),
    detalles: texto(d['texto']),
    estadoTrabajo: EstadoTrabajoX.desdeDb(d['estadoTrabajo']),
    evidencias: listaMapas(d['evidencias']).map(evidenciaDesdeMapa).toList(),
    esAlertaCritica: booleano(d['esAlertaCritica']),
    generadoPorIA: booleano(d['generadoPorIA']),
    createdAt: fecha(d['createdAt']),
  );
}

extension ReporteFirestore on Reporte {
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
}
