// lib/src/features/crear_orden/domain/usecases/crear_orden_casos.dart
// Casos de uso del asistente de creación (P1 → P2).
import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';
import '../repositories/equipo_repositorio.dart';

/// Equipos activos de la planta, para el selector de P1.
class ListarEquiposDePlanta {
  final EquipoRepositorio _equipos;

  const ListarEquiposDePlanta(this._equipos);

  Future<List<Equipo>> ejecutar(String plantaId) =>
      _equipos.deLaPlanta(plantaId);
}

/// Técnicos aprobados de la planta, para el selector de responsable en P2.
class ListarTecnicosDePlanta {
  final UsuarioRepositorio _usuarios;

  const ListarTecnicosDePlanta(this._usuarios);

  Future<List<Usuario>> ejecutar(String plantaId) =>
      _usuarios.tecnicosDePlanta(plantaId);
}

/// Publica la orden y devuelve el id que le asignó la base de datos.
class PublicarOrden {
  final OrdenRepositorio _ordenes;

  const PublicarOrden(this._ordenes);

  Future<String> ejecutar(Orden orden) => _ordenes.crear(orden);
}
