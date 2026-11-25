// lib/src/core/data/repositories/cola_reportes_repositorio_impl.dart
import 'package:uuid/uuid.dart';
import '../../domain/entities/reporte.dart';
import '../../domain/repositories/cola_reportes_repositorio.dart';
import '../datasources/cola_reportes_fuente_local.dart';
import '../json_helpers.dart';
import '../models/reporte_modelo.dart';

/// Traduce entre reportes y filas guardadas. La tecnología de
/// almacenamiento queda en la fuente.
class ColaReportesRepositorioImpl implements ColaReportesRepositorio {
  final ColaReportesFuenteLocal _fuente;

  ColaReportesRepositorioImpl(this._fuente);

  @override
  String nuevoId() => const Uuid().v4();

  @override
  Future<void> guardar(Reporte reporte) async {
    final uid = reporte.autor.uid;
    final filas = await _fuente.leer(uid);
    final fila = {
      ...ReporteModelo.desdeEntidad(reporte).toJson(),
      // toJson no lleva la hora (la pone el servidor): aquí sirve para
      // saber cuándo se escribió mientras espera
      'created_at': aIso(reporte.createdAt),
    };
    // Nunca dos copias: si ya estaba, se reemplaza en su mismo lugar
    final i = filas.indexWhere((f) => f['id'] == reporte.id);
    if (i >= 0) {
      filas[i] = fila;
    } else {
      filas.add(fila);
    }
    await _fuente.escribir(uid, filas);
  }

  /// En el orden en que entraron a la cola: así se envían igual que se
  /// escribieron, aunque dos tengan la misma hora.
  @override
  Future<List<Reporte>> pendientes(String autorUid) async {
    final filas = await _fuente.leer(autorUid);
    return filas.map(ReporteModelo.fromJson).toList();
  }

  @override
  Future<void> quitar(String autorUid, String reporteId) async {
    final filas = await _fuente.leer(autorUid);
    filas.removeWhere((f) => f['id'] == reporteId);
    await _fuente.escribir(autorUid, filas);
  }
}
