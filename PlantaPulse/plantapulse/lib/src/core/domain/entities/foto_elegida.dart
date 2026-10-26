// lib/src/core/domain/entities/foto_elegida.dart
// dart:typed_data es del SDK de Dart, no de Flutter.
import 'dart:typed_data';

/// Una foto que el usuario acaba de tomar o elegir: los bytes (ya
/// comprimidos) y la extensión. Nada más: de dónde salió y cómo se sube
/// es cosa de las fuentes de datos.
class FotoElegida {
  final Uint8List bytes;
  final String extension;   // 'jpg', 'png', 'webp'

  const FotoElegida({required this.bytes, required this.extension});
}
