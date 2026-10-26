// lib/src/core/data/repositories/zona_repositorio_impl.dart
import '../../domain/entities/planta.dart';
import '../../domain/repositories/zona_repositorio.dart';
import '../datasources/zona_fuente_supabase.dart';
import '../models/planta_modelo.dart';

/// Implementación del contrato: traduce filas a entidades.
class ZonaRepositorioImpl implements ZonaRepositorio {
  final ZonaFuenteSupabase _fuente;

  ZonaRepositorioImpl(this._fuente);

  @override
  Future<List<Zona>> deLaPlanta(String plantaId) async {
    final filas = await _fuente.deLaPlanta(plantaId);
    return filas.map(ZonaModelo.fromJson).toList();
  }
}
