// lib/src/features/ordenes/data/datasources/orden_fuente_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/data/data.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/errors/fallos.dart';

/// El único lugar que habla con la tabla 'ordenes'. Devuelve filas
/// crudas; los errores ya salen como FalloApp.
///
/// Limitación de .stream(): admite UN solo filtro .eq(). Por eso el stream
/// filtra por planta en el servidor y el resto se filtra en Dart (en el
/// repositorio). No se descargan datos de más: RLS ya limita las filas a
/// la planta del usuario.
///
/// El orden también se aplica en Dart, sobre DateTime: al llegar un evento
/// en tiempo real, el stream de Supabase reordena comparando las fechas
/// como texto, y el formato del evento no siempre coincide con el de la
/// carga inicial.
class OrdenFuenteSupabase {
  final SupabaseClient _db;

  OrdenFuenteSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('ordenes');

  /// Los errores del stream llegan al Bloc con un mensaje para el aviso.
  static FalloApp _falloDeLectura(Object e) => falloDesdeSupabase(
        e,
        permisos: 'No tienes permiso para ver las órdenes de esta planta.',
        sinConexion: 'Sin conexión. Se muestran los últimos datos recibidos.',
        generico: 'No se pudieron actualizar las órdenes.',
      );

  /// Las órdenes de una planta en tiempo real (incluidas las eliminadas:
  /// RLS las deja leer a propósito, para que el evento de la eliminación
  /// alcance a todos; el repositorio las descarta).
  Stream<List<Map<String, dynamic>>> dePlanta(
    String plantaId,
    String columnaOrden, {
    required bool ascendente,
  }) =>
      _tabla
          .stream(primaryKey: ['id'])
          .eq('planta_id', plantaId)
          .order(columnaOrden, ascending: ascendente)
          .traducirErrores(_falloDeLectura);

  /// UUID v4, el mismo tipo que genera Postgres con gen_random_uuid().
  String nuevoId() => const Uuid().v4();

  /// Inserta y devuelve el id (el que traía o el que generó Postgres).
  /// Aquí SÍ va .select('id'): el supervisor puede leer las órdenes de su
  /// planta. created_at y ultima_actividad los pone el trigger.
  Future<String> insertar(Map<String, dynamic> fila) =>
      traducirSupabase(() async {
        final creada = await _tabla.insert(fila).select('id').single();
        return creada['id'] as String;
      });

  /// ultima_actividad la actualiza el trigger proteger_ordenes.
  Future<void> actualizarEstado(String ordenId, EstadoOrden estado) =>
      traducirSupabase(
          () => _tabla.update({'estado': estado.db}).eq('id', ordenId));

  /// Sin .select(), como todos los update. Si RLS la rechaza no hay error:
  /// simplemente no cambia nada, y el stream del feed lo deja ver.
  /// La fecha va en UTC con aIso, igual que al publicar.
  Future<void> editar({
    required String ordenId,
    required String titulo,
    required String descripcion,
    required String categoria,
    required Prioridad prioridad,
    required DateTime fechaLimite,
  }) =>
      traducirSupabase(() => _tabla.update({
            'titulo': titulo,
            'descripcion': descripcion,
            'categoria': categoria,
            'prioridad': prioridad.db,
            'fecha_limite': aIso(fechaLimite),
          }).eq('id', ordenId));

  /// Por la función del servidor, no con update ni delete: valida que la
  /// orden sea virgen y, si no, devuelve el motivo como error (P0001).
  Future<void> eliminar(String ordenId) => traducirSupabase(
      () => _db.rpc<void>('eliminar_orden', params: {'p_orden_id': ordenId}));

  /// Sin .select(). fecha_cierre en UTC con aIso, como el resto.
  /// El último mantenimiento del equipo lo escribe el trigger al_cerrar_orden.
  Future<void> cerrar({
    required String ordenId,
    required UsuarioRef validadaPor,
    String observaciones = '',
  }) =>
      traducirSupabase(() => _tabla.update({
            'estado': EstadoOrden.completada.db,
            'fecha_cierre': aIso(DateTime.now()),
            'validada_por': refAJson(validadaPor),
            'observaciones_supervisor':
                observaciones.trim().isEmpty ? null : observaciones.trim(),
          }).eq('id', ordenId));

  Future<void> devolver({
    required String ordenId,
    required String observaciones,
  }) =>
      traducirSupabase(() => _tabla.update({
            'estado': EstadoOrden.enProgreso.db,
            'observaciones_supervisor': observaciones.trim(),
          }).eq('id', ordenId));

  /// Con null, los dos campos vuelven a null: la orden queda sin asignar.
  Future<void> asignarTecnico(String ordenId, UsuarioRef? tecnico) =>
      traducirSupabase(() => _tabla.update({
            'asignado_a': tecnico == null ? null : refAJson(tecnico),
            'asignado_a_uid': tecnico?.uid,
          }).eq('id', ordenId));
}
