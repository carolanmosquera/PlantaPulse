// lib/src/core/data/models/equipo_firestore.dart
// TODO fase B: mover a data/models como EquipoModelo con fromJson/toJson.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/equipo.dart';
import '../firestore_helpers.dart';

Equipo equipoDesdeFirestore(DocumentSnapshot doc) {
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

extension EquipoFirestore on Equipo {
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
}
