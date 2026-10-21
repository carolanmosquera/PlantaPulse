// lib/src/features/ordenes/data/repositories/orden_repositorio_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/data/data.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';
import '../../../../core/errors/fallos.dart';

/// Habla SOLO con la tabla 'ordenes'.
///
/// Limitación de .stream(): admite UN solo filtro .eq(). Por eso los dos
/// streams filtran por planta en el servidor y el resto se filtra en Dart.
/// No se descargan datos de más: RLS ya limita las filas a la planta del
/// usuario.
///
/// El orden también se aplica en Dart, sobre DateTime: al llegar un evento
/// en tiempo real, el stream de Supabase reordena comparando las fechas
/// como texto, y el formato del evento no siempre coincide con el de la
/// carga inicial.
class OrdenRepositorioSupabase implements OrdenRepositorio {
  final SupabaseClient _db;

  OrdenRepositorioSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('ordenes');

  /// Los errores del stream llegan al Bloc con un mensaje para el aviso.
  static FalloApp _falloDeLectura(Object e) => falloDesdeSupabase(
        e,
        permisos: 'No tienes permiso para ver las órdenes de esta planta.',
        sinConexion: 'Sin conexión. Se muestran los últimos datos recibidos.',
        generico: 'No se pudieron actualizar las órdenes.',
      );

  Stream<List<Orden>> _dePlanta(String plantaId, String columnaOrden,
          {required bool ascendente}) =>
      _tabla
          .stream(primaryKey: ['id'])
          .eq('planta_id', plantaId)
          .order(columnaOrden, ascending: ascendente)
          // Las eliminadas siguen llegando (RLS las deja leer a propósito,
          // para que el evento de la eliminación alcance a todos) y se
          // descartan aquí: así desaparecen de todas las pantallas abiertas.
          .map((filas) => filas
              .map(OrdenModelo.fromJson)
              .where((o) => !o.eliminada)
              .toList())
          .traducirErrores(_falloDeLectura);

  /// Feed de la planta en tiempo real, las más nuevas primero.
  @override
  Stream<List<Orden>> deLaPlanta(String plantaId, {EstadoOrden? estado}) =>
      _dePlanta(plantaId, 'created_at', ascendente: false).map((ordenes) =>
          ordenes.where((o) => estado == null || o.estado == estado).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  /// "Mis Tareas": stream por planta y filtro por técnico en Dart.
  /// Si una orden se reasigna a otro, el evento llega y aquí desaparece.
  @override
  Stream<List<Orden>> asignadasA(String uid, String plantaId) =>
      _dePlanta(plantaId, 'fecha_limite', ascendente: true).map((ordenes) =>
          ordenes.where((o) => o.asignadoAUid == uid).toList()
            ..sort((a, b) => a.fechaLimite.compareTo(b.fechaLimite)));

  /// UUID v4, el mismo tipo que genera Postgres con gen_random_uuid().
  @override
  String nuevoId() => const Uuid().v4();

  /// Crea la orden y devuelve su id (el que traía o el que generó Postgres).
  /// Aquí SÍ va .select('id'): el supervisor puede leer las órdenes de su
  /// planta. created_at y ultima_actividad los pone el trigger.
  @override
  Future<String> crear(Orden orden) => traducirSupabase(() async {
        final fila = await _tabla
            .insert(OrdenModelo.desdeEntidad(orden).toJson())
            .select('id')
            .single();
        return fila['id'] as String;
      });

  /// ultima_actividad la actualiza el trigger proteger_ordenes.
  @override
  Future<void> actualizarEstado(String ordenId, EstadoOrden estado) =>
      traducirSupabase(
          () => _tabla.update({'estado': estado.db}).eq('id', ordenId));

  /// Sin .select(), como todos los update. Si RLS la rechaza no hay error:
  /// simplemente no cambia nada, y el stream del feed lo deja ver.
  /// La fecha va en UTC con aIso, igual que al publicar.
  @override
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
  @override
  Future<void> eliminar(String ordenId) => traducirSupabase(
      () => _db.rpc<void>('eliminar_orden', params: {'p_orden_id': ordenId}));

  /// Sin .select(). fecha_cierre en UTC con aIso, como el resto.
  /// El último mantenimiento del equipo lo escribe el trigger al_cerrar_orden.
  @override
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

  @override
  Future<void> devolver({
    required String ordenId,
    required String observaciones,
  }) =>
      traducirSupabase(() => _tabla.update({
            'estado': EstadoOrden.enProgreso.db,
            'observaciones_supervisor': observaciones.trim(),
          }).eq('id', ordenId));

  /// Con null, los dos campos vuelven a null: la orden queda sin asignar.
  @override
  Future<void> asignarTecnico(String ordenId, Usuario? tecnico) =>
      traducirSupabase(() => _tabla.update({
            'asignado_a': tecnico == null ? null : refAJson(tecnico.ref),
            'asignado_a_uid': tecnico?.uid,
          }).eq('id', ordenId));
}
