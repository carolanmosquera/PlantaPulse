// lib/src/core/domain/usecases/catalogos.dart
// Casos de uso compartidos por crear_orden y ordenes. Viven en core para
// que el detalle de orden (asignar técnico, editar categoría) no tenga
// que importar el feature crear_orden.
import '../entities/categoria.dart';
import '../entities/usuario.dart';
import '../repositories/categoria_repositorio.dart';
import '../repositories/usuario_repositorio.dart';

/// Técnicos aprobados de la planta, para elegir responsable.
class ListarTecnicosDePlanta {
  final UsuarioRepositorio _usuarios;

  const ListarTecnicosDePlanta(this._usuarios);

  Future<List<Usuario>> ejecutar(String plantaId) =>
      _usuarios.tecnicosDePlanta(plantaId);
}

/// Categorías activas de la planta.
class ListarCategoriasDePlanta {
  final CategoriaRepositorio _categorias;

  const ListarCategoriasDePlanta(this._categorias);

  Future<List<Categoria>> ejecutar(String plantaId) =>
      _categorias.deLaPlanta(plantaId);
}
