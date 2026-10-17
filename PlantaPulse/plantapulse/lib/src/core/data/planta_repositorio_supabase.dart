// lib/src/core/data/planta_repositorio_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/planta.dart';
import '../domain/repositories/planta_repositorio.dart';
import 'fallos_supabase.dart';
import 'models/planta_modelo.dart';

/// Habla SOLO con la tabla 'plantas'. Se crean desde el panel;
/// aquí solo se leen. Lectura pública por RLS.
class PlantaRepositorioSupabase implements PlantaRepositorio {
  final SupabaseClient _db;

  PlantaRepositorioSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  /// Plantas activas ordenadas por nombre, para el selector del admin.
  /// Filtro y orden en Dart, como antes: un 'activo' nulo cuenta como activo.
  @override
  Future<List<Planta>> activas() => traducirSupabase(() async {
        final filas = await _db.from('plantas').select();
        return filas
            .map(PlantaModelo.fromJson)
            .where((p) => p.activo)
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
      });
}
