// lib/src/core/domain/usecases/evidencias.dart
// Casos de uso compartidos de la evidencia fotográfica: leer los reportes
// de una orden, subir fotos y pintarlas. Los usan ordenes, reportes y
// crear_orden.
import 'dart:typed_data';
import '../entities/foto_elegida.dart';
import '../entities/reporte.dart';
import '../repositories/almacenamiento_repositorio.dart';
import '../repositories/reporte_repositorio.dart';

/// Reportes de una orden en tiempo real, en orden cronológico.
class ObservarReportesDeOrden {
  final ReporteRepositorio _reportes;

  const ObservarReportesDeOrden(this._reportes);

  Stream<List<Reporte>> ejecutar(String ordenId) =>
      _reportes.deLaOrden(ordenId);
}

/// Toma una foto con la cámara o la elige de la galería. null si se canceló.
class ObtenerFoto {
  final AlmacenamientoRepositorio _almacenamiento;

  const ObtenerFoto(this._almacenamiento);

  Future<FotoElegida?> ejecutar(OrigenFoto origen) =>
      _almacenamiento.obtenerFoto(origen);
}

/// Sube una foto y devuelve su RUTA (no una URL).
class SubirEvidencia {
  final AlmacenamientoRepositorio _almacenamiento;

  const SubirEvidencia(this._almacenamiento);

  Future<String> ejecutar({
    required String plantaId,
    required String ordenId,
    required Uint8List bytes,
    required String extension,
  }) =>
      _almacenamiento.subir(
        plantaId: plantaId,
        ordenId: ordenId,
        bytes: bytes,
        extension: extension,
      );
}

/// La URL con la que se pinta una evidencia guardada por su ruta.
class UrlDeEvidencia {
  final AlmacenamientoRepositorio _almacenamiento;

  const UrlDeEvidencia(this._almacenamiento);

  String ejecutar(String ruta) => _almacenamiento.urlDe(ruta);
}
