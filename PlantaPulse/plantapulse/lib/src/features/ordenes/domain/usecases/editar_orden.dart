// lib/src/features/ordenes/domain/usecases/editar_orden.dart
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';
import '../../../../core/errors/fallos.dart';

/// Cambia título, descripción, categoría, prioridad y fecha límite.
/// Equipo y zona no se editan: un equipo equivocado se corrige cerrando
/// la orden y abriendo otra.
class EditarOrden {
  final OrdenRepositorio _ordenes;

  const EditarOrden(this._ordenes);

  Future<void> ejecutar({
    required String ordenId,
    required String titulo,
    required String descripcion,
    required String categoria,
    required Prioridad prioridad,
    required DateTime fechaLimite,
  }) =>
      _ordenes.editar(
        ordenId: ordenId,
        titulo: titulo.trim(),
        descripcion: descripcion.trim(),
        categoria: categoria,
        prioridad: prioridad,
        fechaLimite: fechaLimite,
      );
}

/// Elimina una orden creada por equivocación (eliminación lógica).
class EliminarOrden {
  final OrdenRepositorio _ordenes;

  const EliminarOrden(this._ordenes);

  Future<void> ejecutar(String ordenId) => _ordenes.eliminar(ordenId);
}

/// "Invalidar orden" (solo admin): para órdenes falsas que ya tienen
/// trabajo. El motivo es obligatorio: queda en el historial.
class InvalidarOrden {
  static const minMotivo = 5;
  static const maxMotivo = 300;

  final OrdenRepositorio _ordenes;

  const InvalidarOrden(this._ordenes);

  Future<void> ejecutar(String ordenId, String motivo) {
    final texto = motivo.trim();
    if (texto.length < minMotivo || texto.length > maxMotivo) {
      return Future.error(const FalloApp(
          'Escribe el motivo de la invalidación (de $minMotivo a '
          '$maxMotivo caracteres).'));
    }
    return _ordenes.invalidar(ordenId, texto);
  }
}

/// Asigna el responsable de una orden. Con null la deja sin asignar.
class AsignarTecnico {
  final OrdenRepositorio _ordenes;

  const AsignarTecnico(this._ordenes);

  Future<void> ejecutar(String ordenId, Usuario? tecnico) =>
      _ordenes.asignarTecnico(ordenId, tecnico);
}
