// lib/src/features/reportes/data/repositories/reporte_repositorio_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/data.dart';
import '../../../../core/domain/entities/reporte.dart';
import '../../../../core/domain/repositories/reporte_repositorio.dart';
import '../../../../core/errors/fallos.dart';

/// Habla SOLO con la tabla 'reportes'.
///
/// Al insertar, el trigger al_publicar_reporte del servidor actualiza la
/// orden (contadores, ultima_actividad, portada y estado). Aquí NO se toca
/// la orden: duplicaría el trabajo y el técnico ni siquiera tiene permiso
/// para cambiar esos campos.
class ReporteRepositorioSupabase implements ReporteRepositorio {
  final SupabaseClient _db;

  ReporteRepositorioSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('reportes');

  static FalloApp _falloDeLectura(Object e) => falloDesdeSupabase(
        e,
        permisos: 'No tienes permiso para ver los reportes de esta orden.',
        generico: 'No se pudieron cargar los reportes.',
      );

  /// .stream() admite un solo .eq(): se filtra por orden en el servidor y
  /// se ordena en Dart sobre DateTime, igual que OrdenRepositorioSupabase
  /// (el stream reordena comparando las fechas como texto).
  @override
  Stream<List<Reporte>> deLaOrden(String ordenId) => _tabla
      .stream(primaryKey: ['id'])
      .eq('orden_id', ordenId)
      .order('created_at', ascending: true)
      .map((filas) => filas.map(ReporteModelo.fromJson).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
      .traducirErrores(_falloDeLectura);

  /// Sin .select(): nadie necesita la fila de vuelta. La política de
  /// inserción rechaza más de 30 evidencias; la UI no deja llegar ahí.
  @override
  Future<void> crear(Reporte reporte) => traducirSupabase(
      () => _tabla.insert(ReporteModelo.desdeEntidad(reporte).toJson()));
}
