// lib/src/core/domain/entities/foto_pendiente.dart
import 'foto_elegida.dart';

/// Una foto elegida en el teléfono que todavía puede no estar subida.
/// Mientras no tenga ruta vive solo en memoria; al subirse guarda la ruta
/// y la hora, y un reintento ya no la vuelve a subir.
///
/// La foto en sí es una [FotoElegida]; esto añade lo que necesita la
/// interfaz: un id local y el estado de subida.
/// La usan el reporte de avance y el paso 2 de crear orden.
class FotoPendiente {
  final int id;               // clave local, para quitarla sin confundirla
  final FotoElegida foto;
  final String? ruta;
  final DateTime? subidaEn;

  const FotoPendiente({
    required this.id,
    required this.foto,
    this.ruta,
    this.subidaEn,
  });

  bool get subida => ruta != null;

  FotoPendiente subidaA(String ruta, DateTime cuando) => FotoPendiente(
        id: id,
        foto: foto,
        ruta: ruta,
        subidaEn: cuando,
      );

  // Dos fotos son la misma si tienen el mismo id y el mismo estado de
  // subida: así los estados de los Bloc detectan el cambio.
  @override
  bool operator ==(Object other) =>
      other is FotoPendiente && other.id == id && other.ruta == ruta;

  @override
  int get hashCode => Object.hash(id, ruta);
}
