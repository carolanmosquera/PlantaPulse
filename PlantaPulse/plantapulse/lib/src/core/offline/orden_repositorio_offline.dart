
import '../domain/entities/orden.dart';
import '../domain/entities/usuario.dart';
import '../domain/repositories/orden_repositorio.dart';
import 'servicio_offline.dart';

class OrdenRepositorioOffline implements OrdenRepositorio {
  final OrdenRepositorio _original;
  final ServicioOffline _offline;

  OrdenRepositorioOffline(this._original, this._offline);

  @override
  Stream<List<Orden>> deLaPlanta(
    String plantaId, {
    EstadoOrden? estado,
  }) =>
      _original.deLaPlanta(plantaId, estado: estado);

  @override
  Stream<List<Orden>> asignadasA(
    String uid,
    String plantaId,
  ) async* {
    final guardadas = await _offline.leerOrdenes(
      uid: uid,
      plantaId: plantaId,
    );

    if (guardadas.isNotEmpty) {
      yield guardadas;
    }

    await for (final ordenes
        in _original.asignadasA(uid, plantaId)) {
      try {
        await _offline.guardarOrdenes(
          uid: uid,
          plantaId: plantaId,
          ordenes: ordenes,
        );
      } catch (_) {
        // La lectura remota continúa aunque falle la caché.
      }

      yield ordenes;
    }
  }

  @override
  Future<Orden?> obtener(String ordenId) =>
      _original.obtener(ordenId);

  @override
  String nuevoId() => _original.nuevoId();

  @override
  Future<String> crear(Orden orden) =>
      _original.crear(orden);

  @override
  Future<void> actualizarEstado(
    String ordenId,
    EstadoOrden estado,
  ) =>
      _original.actualizarEstado(ordenId, estado);

  @override
  Future<void> editar({
    required String ordenId,
    required String titulo,
    required String descripcion,
    required String categoria,
    required Prioridad prioridad,
    required DateTime fechaLimite,
  }) =>
      _original.editar(
        ordenId: ordenId,
        titulo: titulo,
        descripcion: descripcion,
        categoria: categoria,
        prioridad: prioridad,
        fechaLimite: fechaLimite,
      );

  @override
  Future<void> asignarTecnico(
    String ordenId,
    Usuario? tecnico,
  ) =>
      _original.asignarTecnico(ordenId, tecnico);

  @override
  Future<void> eliminar(String ordenId) =>
      _original.eliminar(ordenId);

  @override
  Future<void> cerrar({
    required String ordenId,
    required UsuarioRef validadaPor,
    String observaciones = '',
  }) =>
      _original.cerrar(
        ordenId: ordenId,
        validadaPor: validadaPor,
        observaciones: observaciones,
      );

  @override
  Future<void> devolver({
    required String ordenId,
    required String observaciones,
  }) =>
      _original.devolver(
        ordenId: ordenId,
        observaciones: observaciones,
      );
}
