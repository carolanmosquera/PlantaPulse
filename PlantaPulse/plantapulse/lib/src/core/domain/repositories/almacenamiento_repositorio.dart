// lib/src/core/domain/repositories/almacenamiento_repositorio.dart
// dart:typed_data es parte del SDK de Dart, no de Flutter: el dominio
// sigue sin depender de ningún framework ni servicio.
import 'dart:typed_data';

/// Dónde viven los archivos de evidencia. Hoy Supabase Storage; mañana
/// podría ser otro servicio sin tocar ni casos de uso ni pantallas.
abstract class AlmacenamientoRepositorio {
  /// Sube los bytes y devuelve la RUTA del objeto, nunca una URL.
  /// La ruta empieza por la planta y la orden:
  /// `planta_id/orden_id/uuid.ext`.
  Future<String> subir({
    required String plantaId,
    required String ordenId,
    required Uint8List bytes,
    required String extension,   // 'jpg', 'png', 'webp'
  });

  /// Convierte una ruta guardada en una URL que se pueda pintar.
  String urlDe(String ruta);
}
