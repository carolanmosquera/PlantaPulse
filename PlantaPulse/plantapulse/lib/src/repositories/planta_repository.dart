// lib/src/repositories/planta_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/planta.dart';

/// Habla SOLO con la colección 'plantas' de Firestore.
/// Las plantas se crean desde la consola; aquí solo se leen.
class PlantaRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('plantas');

  /// Plantas activas ordenadas por nombre, para el selector del admin.
  /// El filtro y el orden se hacen aquí para no necesitar un índice.
  Future<List<Planta>> activas() async {
    final snap = await _col.get();
    return snap.docs
        .map(Planta.desdeFirestore)
        .where((p) => p.activo)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }
}
