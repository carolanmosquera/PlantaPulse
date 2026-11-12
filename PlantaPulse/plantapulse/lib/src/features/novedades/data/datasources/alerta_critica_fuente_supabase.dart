// lib/src/features/novedades/data/datasources/alerta_critica_fuente_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/data.dart';

/// El único lugar que habla con la tabla 'alertas'. Devuelve filas
/// crudas; los errores ya salen como FalloApp.
class AlertaCriticaFuenteSupabase {
  final SupabaseClient? _cliente;

  AlertaCriticaFuenteSupabase({this._cliente});

  /// El cliente se pide al usarlo, no al crear la fuente: así crearla no
  /// exige que Supabase ya esté iniciado (las pruebas no lo inician).
  SupabaseClient get _db => _cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('alertas');

  /// Sin .select(): nadie necesita la fila de vuelta. La política
  /// "alertas alta" exige que la alerta sea de la planta y del autor.
  Future<void> insertar(Map<String, dynamic> fila) async {
    try {
      await _tabla.insert(fila);
    } catch (e) {
      throw falloDesdeSupabase(e,
          permisos: 'No tienes permiso para enviar alertas.',
          generico: 'No se pudo enviar la alerta. Intenta de nuevo.');
    }
  }

  /// .stream() admite un solo .eq(): se filtra por planta en el servidor y
  /// el repositorio filtra el estado y ordena en Dart.
  Stream<List<Map<String, dynamic>>> deLaPlanta(String plantaId) => _tabla
      .stream(primaryKey: ['id'])
      .eq('planta_id', plantaId)
      .traducirErrores((e) => falloDesdeSupabase(
            e,
            permisos: 'No tienes permiso para ver las alertas.',
            generico: 'No se pudieron cargar las alertas.',
          ));
}
