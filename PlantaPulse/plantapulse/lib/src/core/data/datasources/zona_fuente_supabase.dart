// lib/src/core/data/datasources/zona_fuente_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../fallos_supabase.dart';

/// El único lugar que habla con la tabla 'zonas'. Las da de alta el admin
/// desde el panel; aquí solo se leen, para el formulario de alta de equipo.
/// Devuelve filas crudas; los errores ya salen como FalloApp.
class ZonaFuenteSupabase {
  final SupabaseClient _db;

  ZonaFuenteSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> deLaPlanta(String plantaId) =>
      traducirSupabase(() => _db
          .from('zonas')
          .select()
          .eq('planta_id', plantaId)
          .eq('activo', true)
          .order('nombre', ascending: true));
}
