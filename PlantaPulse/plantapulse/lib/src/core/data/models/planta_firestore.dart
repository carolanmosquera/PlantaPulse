// lib/src/core/data/models/planta_firestore.dart
// TODO fase B: mover a data/models como PlantaModelo y ZonaModelo.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/planta.dart';
import '../firestore_helpers.dart';

Planta plantaDesdeFirestore(DocumentSnapshot doc) {
  final d = mapa(doc.data());
  return Planta(
    id: doc.id,
    nombre: texto(d['nombre'], 'Sin nombre'),
    ubicacion: texto(d['ubicacion']),
    activo: booleano(d['activo'], true),
  );
}

extension PlantaFirestore on Planta {
  Map<String, dynamic> aFirestore() => {
        'nombre': nombre,
        'ubicacion': ubicacion,
        'activo': activo,
      };
}

Zona zonaDesdeFirestore(DocumentSnapshot doc) {
  final d = mapa(doc.data());
  return Zona(
    id: doc.id,
    plantaId: texto(d['plantaId']),
    nombre: texto(d['nombre'], 'Sin zona'),
    codigo: texto(d['codigo']),
    descripcion: texto(d['descripcion']),
  );
}

extension ZonaFirestore on Zona {
  Map<String, dynamic> aFirestore() => {
        'plantaId': plantaId,
        'nombre': nombre,
        'codigo': codigo,
        'descripcion': descripcion,
      };
}
