// lib/src/features/crear_orden/domain/repositories/equipo_repositorio.dart
import '../../../../core/domain/entities/equipo.dart';

/// Equipos de la planta. Se leen y, desde el asistente, se dan de alta.
abstract class EquipoRepositorio {
  /// Equipos activos de una planta, ordenados por nombre.
  Future<List<Equipo>> deLaPlanta(String plantaId);

  /// Lee un equipo una sola vez. Devuelve null si no existe.
  Future<Equipo?> obtener(String equipoId);

  /// Registra el equipo y lo devuelve como quedó guardado: con su id y
  /// con zonaNombre resuelto por el servidor a partir de zonaId.
  /// Un serial repetido en la planta llega como FalloApp que lo dice.
  Future<Equipo> crear(Equipo equipo);
}
