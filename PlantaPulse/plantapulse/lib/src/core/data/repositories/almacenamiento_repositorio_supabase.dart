// lib/src/core/data/repositories/almacenamiento_repositorio_supabase.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/almacenamiento_repositorio.dart';
import '../fallos_supabase.dart';

/// Formatos que acepta el bucket, con su tipo MIME.
const _tiposPermitidos = {
  'jpg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

/// 'JPEG', 'jpeg', '.jpg' → 'jpg'. Cualquier otra cosa se trata como jpg:
/// image_picker con imageQuality ya re-codifica la foto a JPEG.
String normalizarExtension(String extension) {
  final e = extension.toLowerCase().replaceFirst('.', '');
  if (e == 'jpeg') return 'jpg';
  return _tiposPermitidos.containsKey(e) ? e : 'jpg';
}

/// `planta_id/orden_id/uuid.ext`.
///
/// La política de subida del bucket comprueba que la PRIMERA carpeta sea
/// la planta del usuario: si la ruta se arma de otra forma, la subida
/// falla con un error de permisos poco obvio.
String rutaEvidencia({
  required String plantaId,
  required String ordenId,
  required String extension,
  String? id,
}) =>
    '$plantaId/$ordenId/${id ?? const Uuid().v4()}.${normalizarExtension(extension)}';

/// Supabase Storage, bucket 'evidencias' (público, 5 MB, jpeg/png/webp).
class AlmacenamientoRepositorioSupabase implements AlmacenamientoRepositorio {
  static const bucket = 'evidencias';

  final SupabaseClient _db;

  AlmacenamientoRepositorioSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  /// Devuelve la ruta que se armó aquí, NO la 'Key' que responde Storage:
  /// esa incluye el nombre del bucket ("evidencias/planta/...") y no es lo
  /// que se guarda.
  @override
  Future<String> subir({
    required String plantaId,
    required String ordenId,
    required Uint8List bytes,
    required String extension,
  }) =>
      traducirSupabase(() async {
        final ext = normalizarExtension(extension);
        final ruta =
            rutaEvidencia(plantaId: plantaId, ordenId: ordenId, extension: ext);
        await _db.storage.from(bucket).uploadBinary(
              ruta,
              bytes,
              fileOptions: FileOptions(
                contentType: _tiposPermitidos[ext],
                upsert: false,   // una evidencia nunca se sobrescribe
              ),
            );
        return ruta;
      });

  /// La URL se calcula siempre desde la ruta. Si algún dato viejo ya trae
  /// una URL completa, se respeta tal cual.
  @override
  String urlDe(String ruta) => ruta.startsWith('http')
      ? ruta
      : _db.storage.from(bucket).getPublicUrl(ruta);
}
