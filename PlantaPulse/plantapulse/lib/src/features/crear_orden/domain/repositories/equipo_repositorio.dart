// lib/src/features/crear_orden/domain/repositories/equipo_repositorio.dart
import '../../../../core/domain/entities/equipo.dart';

/// Equipos de la planta. Se dan de alta desde la consola; aquí solo se leen.
abstract class EquipoRepositorio {
  /// Equipos activos de una planta, ordenados por nombre.
  Future<List<Equipo>> deLaPlanta(String plantaId);

  /// Lee un equipo una sola vez. Devuelve null si no existe.
  Future<Equipo?> obtener(String equipoId);
}
