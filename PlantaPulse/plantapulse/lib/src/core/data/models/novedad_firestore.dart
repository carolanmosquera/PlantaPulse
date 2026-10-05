// lib/src/core/data/models/novedad_firestore.dart
// TODO fase B: mover a data/models como NovedadModelo con fromJson/toJson.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/novedad.dart';
import '../firestore_helpers.dart';
import 'evidencia_mapa.dart';
import 'usuario_firestore.dart';

Novedad novedadDesdeFirestore(DocumentSnapshot doc) {
  final d = mapa(doc.data());
  return Novedad(
    id: doc.id,
    plantaId: texto(d['plantaId']),
    zonaId: texto(d['zonaId']),
    zonaNombre: texto(d['zonaNombre']),
    descripcion: texto(d['descripcion']),
    categoria: CategoriaNovedadX.desdeDb(d['categoria']),
    autor: usuarioRefDesdeMapa(mapa(d['autor'])),
    evidencias: listaMapas(d['evidencias']).map(evidenciaDesdeMapa).toList(),
    estado: EstadoNovedadX.desdeDb(d['estado']),
    ordenId: textoOpcional(d['ordenId']),
    revisadaPor: d['revisadaPor'] == null
        ? null
        : usuarioRefDesdeMapa(mapa(d['revisadaPor'])),
    revisadaEn: fechaOpcional(d['revisadaEn']),
    createdAt: fecha(d['createdAt']),
  );
}

extension NovedadFirestore on Novedad {
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
}
