// lib/src/features/ordenes/domain/usecases/observar_ordenes.dart
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';

/// Feed: todas las órdenes de la planta en tiempo real.
class ObservarOrdenesDePlanta {
  final OrdenRepositorio _ordenes;

  const ObservarOrdenesDePlanta(this._ordenes);

  Stream<List<Orden>> ejecutar(String plantaId, {EstadoOrden? estado}) =>
      _ordenes.deLaPlanta(plantaId, estado: estado);
}

/// "Mis Tareas": las órdenes asignadas a un técnico.
class ObservarMisTareas {
  final OrdenRepositorio _ordenes;

  const ObservarMisTareas(this._ordenes);

  Stream<List<Orden>> ejecutar({required String uid, required String plantaId}) =>
      _ordenes.asignadasA(uid, plantaId);
}
