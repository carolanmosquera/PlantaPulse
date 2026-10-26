// lib/src/core/data/datasources/foto_fuente_dispositivo.dart
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/foto_elegida.dart';
import '../../errors/fallos.dart';

/// El ÚNICO archivo del proyecto que llama a image_picker: la cámara y la
/// galería del teléfono. Los errores (permiso denegado, cámara no
/// disponible) ya salen como FalloApp.
class FotoFuenteDispositivo {
  final ImagePicker _picker;

  FotoFuenteDispositivo({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  Future<FotoElegida?> tomarConCamara() => _obtener(ImageSource.camera);

  Future<FotoElegida?> elegirDeGaleria() => _obtener(ImageSource.gallery);

  /// maxWidth e imageQuality comprimen dentro del propio image_picker: una
  /// foto de varios MB baja a unos cientos de KB, lejos del límite de 5 MB.
  Future<FotoElegida?> _obtener(ImageSource fuente) async {
    final XFile? foto;
    try {
      foto = await _picker.pickImage(
        source: fuente,
        maxWidth: 1600,
        imageQuality: 80,
      );
    } on PlatformException catch (e) {
      throw FalloApp(e.code.contains('denied')
          ? 'PlantaPulse no tiene permiso para usar la cámara o las fotos. '
              'Actívalo en los ajustes del teléfono.'
          : 'No se pudo abrir la cámara o la galería.');
    }
    if (foto == null) return null;                  // el usuario canceló
    final bytes = await foto.readAsBytes();
    final extension =
        foto.name.contains('.') ? foto.name.split('.').last : 'jpg';
    return FotoElegida(bytes: bytes, extension: extension);
  }
}
