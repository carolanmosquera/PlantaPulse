// lib/src/core/data/repositories/planta_repositorio_impl.dart
import '../../domain/entities/planta.dart';
import '../../domain/repositories/planta_repositorio.dart';
import '../datasources/planta_fuente_supabase.dart';
import '../models/planta_modelo.dart';

/// Implementación del contrato. No sabe qué tecnología hay debajo: pide
/// filas a la fuente y las traduce a entidades.
class PlantaRepositorioImpl implements PlantaRepositorio {
  final PlantaFuenteSupabase _fuente;

  PlantaRepositorioImpl(this._fuente);

  /// Plantas activas ordenadas por nombre, para el selector del admin.
  /// Filtro y orden en Dart, como antes: un 'activo' nulo cuenta como activo.
  @override
  Future<List<Planta>> activas() async {
    final filas = await _fuente.todas();
    return filas
        .map(PlantaModelo.fromJson)
        .where((p) => p.activo)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }
}
