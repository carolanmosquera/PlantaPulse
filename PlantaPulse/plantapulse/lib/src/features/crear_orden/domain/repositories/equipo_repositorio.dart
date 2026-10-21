// lib/src/features/crear_orden/domain/repositories/equipo_repositorio.dart
import '../../../../core/domain/entities/equipo.dart';

/// Equipos de la planta. Desde el asistente se leen, se dan de alta, se
/// editan y se dan de baja.
abstract class EquipoRepositorio {
  /// Equipos activos de una planta, ordenados por nombre.
  Future<List<Equipo>> deLaPlanta(String plantaId);

  /// Lee un equipo una sola vez. Devuelve null si no existe.
  Future<Equipo?> obtener(String equipoId);

  /// Registra el equipo y lo devuelve como quedó guardado: con su id y
  /// con zonaNombre resuelto por el servidor a partir de zonaId.
  /// Un serial repetido en la planta llega como FalloApp que lo dice.
  Future<Equipo> crear(Equipo equipo);

  /// Cambia nombre, zona, serial, modelo y tipo. Devuelve el equipo como
  /// quedó (con la zona resuelta por el servidor). Si el cambio no se
  /// aplicó, lanza FalloApp en vez de fingir que se guardó.
  Future<Equipo> editar(Equipo equipo);

  /// "Eliminar" un equipo es darlo de baja (activo = false): las órdenes
  /// viejas lo referencian y su historial no puede quedar apuntando a nada.
  /// Deja de aparecer en el asistente.
  Future<void> darDeBaja(String equipoId);
}
