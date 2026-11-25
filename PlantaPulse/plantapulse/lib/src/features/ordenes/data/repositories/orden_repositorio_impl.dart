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

  /// Las eliminadas y las invalidadas siguen llegando de la fuente y se
  /// descartan aquí: así desaparecen del feed, de Mis Tareas y del resumen
  /// en todas las pantallas abiertas. Las invalidadas siguen en el
  /// Historial (buscarHistorial) y abriéndose por su id (obtener).
  Stream<List<Orden>> _dePlanta(String plantaId, String columnaOrden,
          {required bool ascendente}) =>
      _fuente
          .dePlanta(plantaId, columnaOrden, ascendente: ascendente)
          .map((filas) => filas
              .map(OrdenModelo.fromJson)
              .where((o) => !o.eliminada && !o.invalidada)
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

  /// Las eliminadas cuentan como inexistentes, igual que en el feed.
  @override
  Future<Orden?> obtener(String ordenId) async {
    final fila = await _fuente.obtener(ordenId);
    if (fila == null) return null;
    final orden = OrdenModelo.fromJson(fila);
    return orden.eliminada ? null : orden;
  }

  @override
  Future<List<Orden>> buscarHistorial({
    required String plantaId,
    required String texto,
    String? equipoId,
    required int desde,
    required int limite,
  }) async {
    final filas = await _fuente.buscarHistorial(
      plantaId: plantaId,
      texto: texto,
      equipoId: equipoId,
      desde: desde,
      limite: limite,
    );
    return filas.map(OrdenModelo.fromJson).where((o) => !o.eliminada).toList();
  }

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
  Future<void> invalidar(String ordenId, String motivo) =>
      _fuente.invalidar(ordenId, motivo.trim());

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
