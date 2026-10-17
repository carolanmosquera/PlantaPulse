// lib/src/features/crear_orden/domain/usecases/crear_orden_casos.dart
// Casos de uso del asistente de creación (P1 → P2).
// ListarTecnicosDePlanta y ListarCategoriasDePlanta viven en core
// (core/domain/usecases/catalogos.dart): el detalle de orden también
// los usa.
import '../../../../core/domain/entities/categoria.dart';
import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/planta.dart';
import '../../../../core/domain/repositories/categoria_repositorio.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';
import '../../../../core/domain/repositories/zona_repositorio.dart';
import '../repositories/equipo_repositorio.dart';

/// Equipos activos de la planta, para el selector de P1.
class ListarEquiposDePlanta {
  final EquipoRepositorio _equipos;

  const ListarEquiposDePlanta(this._equipos);

  Future<List<Equipo>> ejecutar(String plantaId) =>
      _equipos.deLaPlanta(plantaId);
}

/// Publica la orden y devuelve el id que le asignó la base de datos.
class PublicarOrden {
  final OrdenRepositorio _ordenes;

  const PublicarOrden(this._ordenes);

  Future<String> ejecutar(Orden orden) => _ordenes.crear(orden);
}

/// Da de alta una categoría y la devuelve con su id.
class CrearCategoria {
  final CategoriaRepositorio _categorias;

  const CrearCategoria(this._categorias);

  Future<Categoria> ejecutar(Categoria categoria) =>
      _categorias.crear(categoria);
}

/// Zonas activas de la planta, para el formulario de alta de equipo.
class ListarZonasDePlanta {
  final ZonaRepositorio _zonas;

  const ListarZonasDePlanta(this._zonas);

  Future<List<Zona>> ejecutar(String plantaId) => _zonas.deLaPlanta(plantaId);
}

/// Registra un equipo. Un equipo recién registrado siempre está operativo.
class CrearEquipo {
  final EquipoRepositorio _equipos;

  const CrearEquipo(this._equipos);

  Future<Equipo> ejecutar({
    required String plantaId,
    required String zonaId,
    required String nombre,
    String serial = '',
    String modelo = '',
    String tipo = '',
  }) =>
      _equipos.crear(Equipo(
        id: '',                     // lo genera la base de datos
        plantaId: plantaId,
        zonaId: zonaId,
        nombre: nombre.trim(),
        serial: serial.trim(),
        modelo: modelo.trim(),
        tipo: tipo,
        estado: EstadoEquipo.operativo,
      ));
}
