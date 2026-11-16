
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/data/fallos_supabase.dart';
import '../../../../core/domain/entities/foto_elegida.dart';
import '../../../../core/errors/fallos.dart';

/// Almacenamiento de fotografías de perfil en Supabase.
class FotoPerfilFuenteSupabase {
  final SupabaseClient _db;

  FotoPerfilFuenteSupabase({
    SupabaseClient? cliente,
  }) : _db = cliente ?? Supabase.instance.client;

  Future<String> subir({
    required String uid,
    required FotoElegida foto,
  }) async {
    // Impedir que un usuario modifique la foto de otro.
    if (_db.auth.currentUser?.id != uid) {
      throw const FalloPermisos(
        'Solo puedes cambiar tu propia fotografía.',
      );
    }

    final extension = foto.extension
        .toLowerCase()
        .replaceFirst('.', '');

    final ext = extension == 'jpeg' ? 'jpg' : extension;

    const tipos = {
      'jpg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };

    if (!tipos.containsKey(ext)) {
      throw const FalloApp(
        'Formato de imagen no admitido.',
      );
    }

    if (foto.bytes.length > 5242880) {
      throw const FalloApp(
        'La foto es demasiado grande (máximo 5 MB).',
      );
    }

    // Cada usuario tendrá sus fotografías dentro de su UID.
    final ruta = '$uid/${const Uuid().v4()}.$ext';

    return traducirSupabase(() async {
      await _db.storage.from('avatares').uploadBinary(
        ruta,
        foto.bytes,
        fileOptions: FileOptions(
          contentType: tipos[ext],
          upsert: false,
        ),
      );

      return _db.storage.from('avatares').getPublicUrl(ruta);
    });
  }
}
