// lib/src/features/ordenes/data/repositories/orden_repositorio_impl.dart
import '../../../../core/data/models/orden_modelo.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';
import '../datasources/orden_fuente_supabase.dart';

/// Implementación del contrato. No sabe qué base de datos hay debajo:
/// traduce filas a entidades y hace en memoria lo que la fuente no puede
/// pedir (filtros finos y orden sobre DateTime; ver OrdenFuenteSupabase).
class OrdenRepositorioImpl implements OrdenRepositorio {
  final OrdenFuenteSupabase _fuente;

  OrdenRepositorioImpl(this._fuente);

  /// Las eliminadas siguen llegando de la fuente y se descartan aquí:
  /// así desaparecen de todas las pantallas abiertas.
  Stream<List<Orden>> _dePlanta(String plantaId, String columnaOrden,
          {required bool ascendente}) =>
      _fuente
          .dePlanta(plantaId, columnaOrden, ascendente: ascendente)
          .map((filas) => filas
              .map(OrdenModelo.fromJson)
              .where((o) => !o.eliminada)
              .toList());

  /// Feed de la planta en tiempo real, las más nuevas primero.
  @override
  Stream<List<Orden>> deLaPlanta(String plantaId, {EstadoOrden? estado}) =>
      _dePlanta(plantaId, 'created_at', ascendente: false).map((ordenes) =>
          ordenes.where((o) => estado == null || o.estado == estado).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  /// "Mis Tareas": stream por planta y filtro por técnico en Dart.
  /// Si una orden se reasigna a otro, el evento llega y aquí desaparece.
  @override
  Stream<List<Orden>> asignadasA(String uid, String plantaId) =>
      _dePlanta(plantaId, 'fecha_limite', ascendente: true).map((ordenes) =>
          ordenes.where((o) => o.asignadoAUid == uid).toList()
            ..sort((a, b) => a.fechaLimite.compareTo(b.fechaLimite)));

  @override
  String nuevoId() => _fuente.nuevoId();

  @override
  Future<String> crear(Orden orden) =>
      _fuente.insertar(OrdenModelo.desdeEntidad(orden).toJson());

  @override
  Future<void> actualizarEstado(String ordenId, EstadoOrden estado) =>
      _fuente.actualizarEstado(ordenId, estado);

  @override
  Future<void> editar({
    required String ordenId,
    required String titulo,
    required String descripcion,
    required String categoria,
    required Prioridad prioridad,
    required DateTime fechaLimite,
  }) =>
      _fuente.editar(
        ordenId: ordenId,
        titulo: titulo,
        descripcion: descripcion,
        categoria: categoria,
        prioridad: prioridad,
        fechaLimite: fechaLimite,
      );

  @override
  Future<void> eliminar(String ordenId) => _fuente.eliminar(ordenId);

  @override
  Future<void> cerrar({
    required String ordenId,
    required UsuarioRef validadaPor,
    String observaciones = '',
  }) =>
      _fuente.cerrar(
        ordenId: ordenId,
        validadaPor: validadaPor,
        observaciones: observaciones,
      );

  @override
  Future<void> devolver({
    required String ordenId,
    required String observaciones,
  }) =>
      _fuente.devolver(ordenId: ordenId, observaciones: observaciones);

  @override
  Future<void> asignarTecnico(String ordenId, Usuario? tecnico) =>
      _fuente.asignarTecnico(ordenId, tecnico?.ref);
}
