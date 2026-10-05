// lib/src/features/crear_orden/data/repositories/equipo_repositorio_firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/data.dart';
import '../../../../core/domain/entities/equipo.dart';
import '../../domain/repositories/equipo_repositorio.dart';

/// Habla SOLO con la colección 'equipos' de Firestore.
/// Los equipos se dan de alta desde la consola; aquí solo se leen.
class EquipoRepositorioFirestore implements EquipoRepositorio {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('equipos');

  /// Equipos activos de una planta, ordenados por nombre, para el
  /// selector del asistente de creación (paso 1).
  /// Necesita el índice compuesto plantaId + activo + nombre.
  @override
  Future<List<Equipo>> deLaPlanta(String plantaId) =>
      traducirFirestore(() async {
        final snap = await _col
            .where('plantaId', isEqualTo: plantaId)
            .where('activo', isEqualTo: true)
            .orderBy('nombre')
            .get();
        return snap.docs.map(equipoDesdeFirestore).toList();
      });

  /// Lee un equipo una sola vez. Devuelve null si no existe.
  @override
  Future<Equipo?> obtener(String equipoId) => traducirFirestore(() async {
        final doc = await _col.doc(equipoId).get();
        if (!doc.exists) return null;
        return equipoDesdeFirestore(doc);
      });
}
