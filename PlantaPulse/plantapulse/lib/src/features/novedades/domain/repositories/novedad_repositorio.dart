import '../../../../core/domain/entities/novedad.dart';
import '../../../../core/domain/entities/orden.dart';

abstract class NovedadRepositorio {
  Stream<List<Novedad>> deLaPlanta(String plantaId);
  Future<Novedad?> obtener(String novedadId);
  String nuevoId();
  Future<Novedad> publicar(Novedad novedad);

  /// Publica la orden asignada y registra el vínculo en una sola operación.
  Future<String> convertir(String novedadId, Orden orden);
  Future<void> descartar(String novedadId, String motivo);
}
