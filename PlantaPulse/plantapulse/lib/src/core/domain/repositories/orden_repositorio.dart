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

  /// Un id nuevo para una orden que aún no existe. Sirve para subir sus
  /// fotos a su carpeta ANTES de crearla: si una subida falla, la orden no
  /// se crea y no queda a medias.
  String nuevoId();

  /// Crea la orden y devuelve su id. Si la orden ya trae id (de
  /// [nuevoId]), se usa ese; si no, lo genera la base de datos.
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

  /// Elimina una orden creada por equivocación. Es una eliminación
  /// lógica: la orden deja de aparecer en el feed y en Mis Tareas, pero
  /// queda en la base con quién la eliminó y cuándo.
  ///
  /// Solo una orden pendiente y sin reportes, alertas ni novedades. Si no
  /// se puede, lanza FalloApp con el motivo; a diferencia de un update,
  /// el rechazo nunca es silencioso.
  Future<void> eliminar(String ordenId);

  /// "Aprobar y cerrar": la orden pasa a completada, con fecha de cierre,
  /// quién la validó y las observaciones si hay. El servidor actualiza
  /// solo el último mantenimiento del equipo.
  Future<void> cerrar({
    required String ordenId,
    required UsuarioRef validadaPor,
    String observaciones = '',
  });

  /// "Solicitar correcciones": la orden vuelve a en progreso con las
  /// observaciones, y el técnico la ve otra vez en Mis Tareas.
  Future<void> devolver({
    required String ordenId,
    required String observaciones,
  });
}
