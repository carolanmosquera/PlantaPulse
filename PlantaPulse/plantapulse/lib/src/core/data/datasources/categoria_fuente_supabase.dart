// lib/src/core/data/datasources/categoria_fuente_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../fallos_supabase.dart';

/// El único lugar que habla con la tabla 'categorias'. La lista se carga
/// una vez al abrir el asistente; la tabla está en Realtime, pero no hace
/// falta un stream para esto.
/// Devuelve filas crudas; los errores ya salen como FalloApp.
class CategoriaFuenteSupabase {
  final SupabaseClient _db;

  CategoriaFuenteSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('categorias');

  Future<List<Map<String, dynamic>>> deLaPlanta(String plantaId) =>
      traducirSupabase(() => _tabla
          .select()
          .eq('planta_id', plantaId)
          .eq('activo', true)
          .order('nombre', ascending: true));

  /// Aquí SÍ va .select().single(): hace falta el id, y quien puede
  /// crear categorías puede leer las de su planta.
  Future<Map<String, dynamic>> insertar(Map<String, dynamic> fila) =>
      traducirSupabase(
        () => _tabla.insert(fila).select().single(),
        // Índice único (planta_id, lower(nombre))
        duplicado: 'Ya existe una categoría con ese nombre.',
      );
}
