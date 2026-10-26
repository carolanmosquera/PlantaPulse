// lib/src/features/reportes/data/datasources/reporte_fuente_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/data.dart';
import '../../../../core/errors/fallos.dart';

/// El único lugar que habla con la tabla 'reportes'. Devuelve filas
/// crudas; los errores ya salen como FalloApp.
///
/// Al insertar, el trigger al_publicar_reporte del servidor actualiza la
/// orden (contadores, ultima_actividad, portada y estado). Aquí NO se toca
/// la orden: duplicaría el trabajo y el técnico ni siquiera tiene permiso
/// para cambiar esos campos.
class ReporteFuenteSupabase {
  final SupabaseClient _db;

  ReporteFuenteSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('reportes');

  static FalloApp _falloDeLectura(Object e) => falloDesdeSupabase(
        e,
        permisos: 'No tienes permiso para ver los reportes de esta orden.',
        generico: 'No se pudieron cargar los reportes.',
      );

  /// .stream() admite un solo .eq(): se filtra por orden en el servidor y
  /// el repositorio ordena en Dart sobre DateTime, igual que con las
  /// órdenes (el stream reordena comparando las fechas como texto).
  Stream<List<Map<String, dynamic>>> deLaOrden(String ordenId) => _tabla
      .stream(primaryKey: ['id'])
      .eq('orden_id', ordenId)
      .order('created_at', ascending: true)
      .traducirErrores(_falloDeLectura);

  /// Sin .select(): nadie necesita la fila de vuelta. La política de
  /// inserción rechaza más de 30 evidencias; la UI no deja llegar ahí.
  Future<void> insertar(Map<String, dynamic> fila) =>
      traducirSupabase(() => _tabla.insert(fila));
}
