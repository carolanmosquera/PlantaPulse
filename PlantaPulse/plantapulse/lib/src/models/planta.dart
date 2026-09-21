// lib/src/models/planta.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

class Planta {
  final String id;
  final String nombre;      // "Planta Norte"
  final String ubicacion;   // ciudad o dirección
  final bool activo;

  const Planta({
    required this.id,
    required this.nombre,
    this.ubicacion = '',
    this.activo = true,
  });

  factory Planta.desdeFirestore(DocumentSnapshot doc) {
    final d = mapa(doc.data());
    return Planta(
      id: doc.id,
      nombre: texto(d['nombre'], 'Sin nombre'),
      ubicacion: texto(d['ubicacion']),
      activo: booleano(d['activo'], true),
    );
  }

  Map<String, dynamic> aFirestore() => {
        'nombre': nombre,
        'ubicacion': ubicacion,
        'activo': activo,
      };
}

class Zona {
  final String id;
  final String plantaId;
  final String nombre;      // "Sector de Empaque"
  final String codigo;      // "ZN-04"
  final String descripcion;

  const Zona({
    required this.id,
    required this.plantaId,
    required this.nombre,
    this.codigo = '',
    this.descripcion = '',
  });

  factory Zona.desdeFirestore(DocumentSnapshot doc) {
    final d = mapa(doc.data());
    return Zona(
      id: doc.id,
      plantaId: texto(d['plantaId']),
      nombre: texto(d['nombre'], 'Sin zona'),
      codigo: texto(d['codigo']),
      descripcion: texto(d['descripcion']),
    );
  }

  Map<String, dynamic> aFirestore() => {
        'plantaId': plantaId,
        'nombre': nombre,
        'codigo': codigo,
        'descripcion': descripcion,
      };
}