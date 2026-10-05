// lib/src/core/data/models/orden_firestore.dart
// TODO fase B: mover a data/models como OrdenModelo con fromJson/toJson.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/orden.dart';
import '../firestore_helpers.dart';
import 'usuario_firestore.dart';

Orden ordenDesdeFirestore(DocumentSnapshot doc) {
  final d = mapa(doc.data());
  final asignado = usuarioRefDesdeMapa(mapa(d['asignadoA']));
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
    creadoPor: usuarioRefDesdeMapa(mapa(d['creadoPor'])),
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
        : usuarioRefDesdeMapa(mapa(d['validadaPor'])),
    observacionesSupervisor: textoOpcional(d['observacionesSupervisor']),
  );
}

extension OrdenFirestore on Orden {
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
}
