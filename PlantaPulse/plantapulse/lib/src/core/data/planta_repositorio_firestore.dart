// lib/src/core/data/planta_repositorio_firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/planta.dart';
import '../domain/repositories/planta_repositorio.dart';
import 'fallos_firestore.dart';
import 'models/planta_firestore.dart';

/// Habla SOLO con la colección 'plantas' de Firestore.
/// Las plantas se crean desde la consola; aquí solo se leen.
class PlantaRepositorioFirestore implements PlantaRepositorio {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('plantas');

  /// Plantas activas ordenadas por nombre, para el selector del admin.
  /// El filtro y el orden se hacen aquí para no necesitar un índice.
  @override
  Future<List<Planta>> activas() => traducirFirestore(() async {
        final snap = await _col.get();
        return snap.docs
            .map(plantaDesdeFirestore)
            .where((p) => p.activo)
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
      });
}
