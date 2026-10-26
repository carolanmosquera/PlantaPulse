// lib/src/features/crear_orden/data/repositories/equipo_repositorio_impl.dart
import '../../../../core/data/models/equipo_modelo.dart';
import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/errors/fallos.dart';
import '../../domain/repositories/equipo_repositorio.dart';
import '../datasources/equipo_fuente_supabase.dart';

/// Implementación del contrato. No sabe qué base de datos hay debajo:
/// traduce filas a entidades y, si un cambio no se aplicó, lo dice en vez
/// de fingir que se guardó.
class EquipoRepositorioImpl implements EquipoRepositorio {
  final EquipoFuenteSupabase _fuente;

  EquipoRepositorioImpl(this._fuente);

  @override
  Future<List<Equipo>> deLaPlanta(String plantaId) async {
    final filas = await _fuente.deLaPlanta(plantaId);
    return filas.map(EquipoModelo.fromJson).toList();
  }

  @override
  Future<Equipo?> obtener(String equipoId) async {
    final fila = await _fuente.obtener(equipoId);
    return fila == null ? null : EquipoModelo.fromJson(fila);
  }

  @override
  Future<Equipo> crear(Equipo equipo) async {
    final fila =
        await _fuente.insertar(EquipoModelo.desdeEntidad(equipo).toJson());
    return EquipoModelo.fromJson(fila);
  }

  /// Un update rechazado por RLS no da error: la fuente relee la fila y
  /// avisa si no trae lo que se mandó.
  @override
  Future<Equipo> editar(Equipo equipo) async {
    final r = await _fuente.editar(
      equipo.id,
      nombre: equipo.nombre,
      zonaId: equipo.zonaId,
      serial: equipo.serial,
      modelo: equipo.modelo,
      tipo: equipo.tipo,
    );
    if (!r.aplicado) {
      throw const FalloPermisos(
          'No se pudo guardar el equipo: no tienes permiso para editarlo.');
    }
    return EquipoModelo.fromJson(r.fila);
  }

  @override
  Future<void> darDeBaja(String equipoId) async {
    final activo = await _fuente.darDeBaja(equipoId);
    if (activo == true) {
      throw const FalloPermisos(
          'No se pudo dar de baja: no tienes permiso para editar este equipo.');
    }
  }
}
