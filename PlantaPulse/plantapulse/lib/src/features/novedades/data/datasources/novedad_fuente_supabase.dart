import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/fallos_supabase.dart';
import '../../../../core/errors/fallos.dart';

class NovedadFuenteSupabase {
  final SupabaseClient? _cliente;

  NovedadFuenteSupabase([this._cliente]);

  SupabaseClient get _db => _cliente ?? Supabase.instance.client;
  SupabaseQueryBuilder get _tabla => _db.from('novedades');

  Stream<List<Map<String, dynamic>>> dePlanta(String plantaId) async* {
    try {
      yield* _tabla
          .stream(primaryKey: ['id'])
          .eq('planta_id', plantaId)
          .order('created_at', ascending: false);
    } catch (e) {
      throw falloDesdeSupabase(
        e,
        generico: 'No se pudieron consultar las novedades de la planta.',
      );
    }
  }

  Future<Map<String, dynamic>?> obtener(String id) =>
      traducirSupabase(() => _tabla.select().eq('id', id).maybeSingle());

  Future<Map<String, dynamic>> publicar(Map<String, dynamic> fila) =>
      traducirSupabase(() async {
        final publicada = await _tabla
            .upsert(fila, onConflict: 'id', ignoreDuplicates: true)
            .select()
            .maybeSingle();
        if (publicada != null) return publicada;

        // Si se perdió la respuesta del alta, recupera la novedad del autor.
        final anterior = await _tabla
            .select()
            .eq('id', fila['id'])
            .eq('autor->>uid', fila['autor']['uid'])
            .maybeSingle();
        if (anterior != null) return anterior;
        throw const FalloApp('No se pudo confirmar la publicación.');
      });

  Future<String> convertir(String id, Map<String, dynamic> orden) =>
      traducirSupabase(
        () => _db.rpc<String>(
          'convertir_novedad',
          params: {'p_novedad_id': id, 'p_orden': orden},
        ),
      );

  Future<void> descartar(String id, String motivo) => traducirSupabase(
    () => _db.rpc<void>(
      'descartar_novedad',
      params: {'p_novedad_id': id, 'p_motivo': motivo},
    ),
  );
}
