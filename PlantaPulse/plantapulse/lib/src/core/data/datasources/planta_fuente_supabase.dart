// lib/src/core/data/datasources/planta_fuente_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../fallos_supabase.dart';

/// El único lugar que habla con la tabla 'plantas'. Se crean desde el
/// panel; aquí solo se leen. Lectura pública por RLS.
/// Devuelve filas crudas; los errores ya salen como FalloApp.
class PlantaFuenteSupabase {
  final SupabaseClient _db;

  PlantaFuenteSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  /// Todas las plantas. El filtro de activas y el orden los hace el
  /// repositorio en Dart: un 'activo' nulo cuenta como activo.
  Future<List<Map<String, dynamic>>> todas() =>
      traducirSupabase(() => _db.from('plantas').select());
}
