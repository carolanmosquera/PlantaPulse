// lib/src/core/data/repositories/categoria_repositorio_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/repositories/categoria_repositorio.dart';
import '../fallos_supabase.dart';
import '../models/categoria_modelo.dart';

/// Habla SOLO con la tabla 'categorias'. La lista se carga una vez al
/// abrir el asistente; la tabla está en Realtime, pero no hace falta
/// un stream para esto.
class CategoriaRepositorioSupabase implements CategoriaRepositorio {
  final SupabaseClient _db;

  CategoriaRepositorioSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('categorias');

  @override
  Future<List<Categoria>> deLaPlanta(String plantaId) =>
      traducirSupabase(() async {
        final filas = await _tabla
            .select()
            .eq('planta_id', plantaId)
            .eq('activo', true)
            .order('nombre', ascending: true);
        return filas.map(CategoriaModelo.fromJson).toList();
      });

  /// Aquí SÍ va .select().single(): hace falta el id, y quien puede
  /// crear categorías puede leer las de su planta.
  @override
  Future<Categoria> crear(Categoria categoria) => traducirSupabase(
        () async {
          final fila = await _tabla
              .insert(CategoriaModelo.desdeEntidad(categoria).toJson())
              .select()
              .single();
          return CategoriaModelo.fromJson(fila);
        },
        // Índice único (planta_id, lower(nombre))
        duplicado: 'Ya existe una categoría con ese nombre.',
      );
}
