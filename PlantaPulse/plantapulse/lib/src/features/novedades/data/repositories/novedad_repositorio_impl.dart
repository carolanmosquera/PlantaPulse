import 'package:uuid/uuid.dart';
import '../../../../core/data/models/novedad_modelo.dart';
import '../../../../core/data/models/orden_modelo.dart';
import '../../../../core/domain/entities/novedad.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../domain/repositories/novedad_repositorio.dart';
import '../datasources/novedad_fuente_supabase.dart';

class NovedadRepositorioImpl implements NovedadRepositorio {
  final NovedadFuenteSupabase _fuente;

  NovedadRepositorioImpl(this._fuente);

  @override
  Stream<List<Novedad>> deLaPlanta(String plantaId) => _fuente
      .dePlanta(plantaId)
      .map(
        (filas) =>
            filas.map(NovedadModelo.fromJson).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  @override
  Future<Novedad?> obtener(String novedadId) async {
    final fila = await _fuente.obtener(novedadId);
    return fila == null ? null : NovedadModelo.fromJson(fila);
  }

  @override
  String nuevoId() => const Uuid().v4();

  @override
  Future<Novedad> publicar(Novedad novedad) async => NovedadModelo.fromJson(
    await _fuente.publicar(NovedadModelo.desdeEntidad(novedad).toJson()),
  );

  @override
  Future<String> convertir(String novedadId, Orden orden) =>
      _fuente.convertir(novedadId, OrdenModelo.desdeEntidad(orden).toJson());

  @override
  Future<void> descartar(String novedadId, String motivo) =>
      _fuente.descartar(novedadId, motivo);
}
