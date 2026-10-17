// lib/src/core/data/repositories/zona_repositorio_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/planta.dart';
import '../../domain/repositories/zona_repositorio.dart';
import '../fallos_supabase.dart';
import '../models/planta_modelo.dart';

/// Habla SOLO con la tabla 'zonas'. Las da de alta el admin desde el
/// panel; aquí solo se leen, para el formulario de alta de equipo.
class ZonaRepositorioSupabase implements ZonaRepositorio {
  final SupabaseClient _db;

  ZonaRepositorioSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  @override
  Future<List<Zona>> deLaPlanta(String plantaId) => traducirSupabase(() async {
        final filas = await _db
            .from('zonas')
            .select()
            .eq('planta_id', plantaId)
            .eq('activo', true)
            .order('nombre', ascending: true);
        return filas.map(ZonaModelo.fromJson).toList();
      });
}
