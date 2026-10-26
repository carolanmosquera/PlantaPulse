// lib/src/core/data/repositories/almacenamiento_repositorio_impl.dart
import 'dart:typed_data';
import '../../domain/entities/foto_elegida.dart';
import '../../domain/repositories/almacenamiento_repositorio.dart';
import '../datasources/almacenamiento_fuente_supabase.dart';
import '../datasources/foto_fuente_dispositivo.dart';

/// Compone DOS fuentes: el dispositivo (de donde sale la foto) y Supabase
/// Storage (donde se guarda). Es el motivo de la capa de fuentes: con los
/// SDK metidos aquí adentro, juntar dos orígenes sería un revoltijo.
/// Esta clase no sabe qué hay debajo de ninguna de las dos.
class AlmacenamientoRepositorioImpl implements AlmacenamientoRepositorio {
  final FotoFuenteDispositivo _dispositivo;
  final AlmacenamientoFuenteSupabase _almacen;

  AlmacenamientoRepositorioImpl({
    required this._dispositivo,
    required this._almacen,
  });

  @override
  Future<FotoElegida?> obtenerFoto(OrigenFoto origen) => switch (origen) {
        OrigenFoto.camara => _dispositivo.tomarConCamara(),
        OrigenFoto.galeria => _dispositivo.elegirDeGaleria(),
      };

  @override
  Future<String> subir({
    required String plantaId,
    required String ordenId,
    required Uint8List bytes,
    required String extension,
  }) =>
      _almacen.subir(
        plantaId: plantaId,
        ordenId: ordenId,
        bytes: bytes,
        extension: extension,
      );

  /// La URL se calcula siempre desde la ruta. Si algún dato viejo ya trae
  /// una URL completa, se respeta tal cual.
  @override
  String urlDe(String ruta) =>
      ruta.startsWith('http') ? ruta : _almacen.urlPublica(ruta);
}
