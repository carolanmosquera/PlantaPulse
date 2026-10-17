// lib/src/core/domain/repositories/orden_repositorio.dart
import '../entities/orden.dart';
import '../entities/usuario.dart';

/// Órdenes de trabajo. En core porque lo usan ordenes (leer)
/// y crear_orden (publicar).
abstract class OrdenRepositorio {
  /// Feed de la planta en tiempo real, las más nuevas primero.
  Stream<List<Orden>> deLaPlanta(String plantaId, {EstadoOrden? estado});

  /// "Mis Tareas": las órdenes de un técnico, la que vence primero arriba.
  Stream<List<Orden>> asignadasA(String uid, String plantaId);

  /// Crea la orden y devuelve el id que le asignó la base de datos.
  Future<String> crear(Orden orden);

  Future<void> actualizarEstado(String ordenId, EstadoOrden estado);

  /// Cambia los datos descriptivos. Equipo y zona NO se editan: cambiarlos
  /// convertiría la orden en otra y el historial del equipo mentiría.
  Future<void> editar({
    required String ordenId,
    required String titulo,
    required String descripcion,
    required String categoria,
    required Prioridad prioridad,
    required DateTime fechaLimite,
  });

  /// Asigna el responsable. Con null, la orden queda sin asignar.
  Future<void> asignarTecnico(String ordenId, Usuario? tecnico);
}
