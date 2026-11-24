import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/data.dart';
import '../../../../core/errors/fallos.dart';

class AvisosFuenteSupabase {
  final SupabaseClient? _cliente;

  AvisosFuenteSupabase({SupabaseClient? cliente}) : _cliente = cliente;

  SupabaseClient get _db => _cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('notificaciones');

  Stream<List<Map<String, dynamic>>> delUsuario(String usuarioId) => _tabla
      .stream(primaryKey: ['id'])
      .eq('usuario_id', usuarioId)
      .traducirErrores((e) => falloDesdeSupabase(
            e,
            permisos: 'No tienes permiso para ver estos avisos.',
            sinConexion: 'Sin conexión. No se pudieron actualizar los avisos.',
            generico: 'No se pudieron cargar los avisos.',
          ));

  Future<void> marcarLeida({
    required String usuarioId,
    required String avisoId,
  }) =>
      traducirSupabase(() async {
        final fila = await _tabla
            .update({'leida': true})
            .eq('id', avisoId)
            .eq('usuario_id', usuarioId)
            .select('id')
            .maybeSingle();
        if (fila == null) {
          throw const FalloApp('El aviso ya no existe o no tienes permiso.');
        }
      });
}
