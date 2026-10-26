// lib/src/core/domain/entities/evidencia.dart

/// Una foto de evidencia de mantenimiento.
///
/// Se guarda la RUTA del archivo en el almacenamiento, nunca la URL: si
/// cambia el bucket, el proyecto o la visibilidad, la URL se recalcula
/// desde la ruta y el historial no se pierde. La URL para pintarla la da
/// AlmacenamientoRepositorio.urlDe().
///
/// Quién la subió y cuándo es lo que la convierte en evidencia y no en un
/// simple adjunto.
class Evidencia {
  /// `planta_id/orden_id/uuid.jpg`
  final String ruta;
  final DateTime subidaEn;
  final String autorUid;

  const Evidencia({
    required this.ruta,
    required this.subidaEn,
    required this.autorUid,
  });
}

/// Tope de fotos por reporte. La política de inserción de 'reportes' lo
/// comprueba (jsonb_array_length(evidencias) <= 30) y rechaza la número 31,
/// así que la UI no debe dejar llegar a ese punto.
const int maxFotosPorReporte = 30;
