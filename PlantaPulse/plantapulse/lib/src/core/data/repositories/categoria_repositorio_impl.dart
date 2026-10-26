// lib/src/core/data/repositories/categoria_repositorio_impl.dart
import '../../domain/entities/categoria.dart';
import '../../domain/repositories/categoria_repositorio.dart';
import '../datasources/categoria_fuente_supabase.dart';
import '../models/categoria_modelo.dart';

/// Implementación del contrato: traduce entre filas y entidades. La
/// tecnología queda en la fuente.
class CategoriaRepositorioImpl implements CategoriaRepositorio {
  final CategoriaFuenteSupabase _fuente;

  CategoriaRepositorioImpl(this._fuente);

  @override
  Future<List<Categoria>> deLaPlanta(String plantaId) async {
    final filas = await _fuente.deLaPlanta(plantaId);
    return filas.map(CategoriaModelo.fromJson).toList();
  }

  /// Devuelve la categoría con el id que le asignó la base. Un nombre
  /// repetido ya llega de la fuente como FalloApp con su mensaje.
  @override
  Future<Categoria> crear(Categoria categoria) async {
    final fila = await _fuente
        .insertar(CategoriaModelo.desdeEntidad(categoria).toJson());
    return CategoriaModelo.fromJson(fila);
  }
}
