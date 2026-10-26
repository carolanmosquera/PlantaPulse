// lib/src/features/auth/data/datasources/usuario_fuente_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/data.dart';
import '../../../../core/domain/entities/usuario.dart';

/// El único lugar que habla con la tabla 'usuarios'. No sabe nada de
/// contraseñas. Devuelve filas crudas; los errores ya salen como FalloApp.
///
/// Regla: los update() NO llevan .select(). Pedir la fila de vuelta
/// exige poder leerla, y el admin no puede leer el perfil que acaba de
/// aprobar si quedó en otra planta: la actualización fallaría.
class UsuarioFuenteSupabase {
  final SupabaseClient _db;

  UsuarioFuenteSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('usuarios');

  /// Crea el perfil. El id es el uid de auth.users.
  /// created_at lo pone el trigger con la hora del servidor.
  Future<void> insertar(Map<String, dynamic> fila) =>
      traducirSupabase(() => _tabla.insert(fila));

  /// Una fila, o null si no existe (o si RLS no deja verla: en Postgres
  /// eso no es un error, solo no hay filas).
  Future<Map<String, dynamic>?> obtener(String uid) =>
      traducirSupabase(() => _tabla.select().eq('id', uid).maybeSingle());

  /// El perfil en tiempo real.
  Stream<List<Map<String, dynamic>>> escuchar(String uid) => _tabla
      .stream(primaryKey: ['id'])
      .eq('id', uid)
      .traducirErrores(falloDesdeSupabase);

  /// Actualiza solo los campos que cambian. Las claves llegan con los
  /// nombres de las propiedades de la entidad (fcmToken) y aquí se
  /// traducen a columnas (fcm_token). Qué columnas puede tocar cada quien
  /// lo decide el trigger proteger_usuarios.
  Future<void> actualizar(String uid, Map<String, dynamic> cambios) =>
      traducirSupabase(() => _tabla.update({
            for (final c in cambios.entries) aColumna(c.key): _valor(c.value),
          }).eq('id', uid));

  static Object? _valor(Object? v) => switch (v) {
        DateTime f => aIso(f),
        UsuarioRef r => refAJson(r),
        _ => v,
      };

  /// Técnicos activos y aprobados de una planta (sin ordenar: el orden por
  /// nombre lo hace el repositorio en Dart, igual que antes).
  Future<List<Map<String, dynamic>>> tecnicosDePlanta(String plantaId) =>
      traducirSupabase(() => _tabla
          .select()
          .eq('planta_id', plantaId)
          .eq('rol', RolUsuario.tecnico.db)
          .eq('estado', EstadoCuenta.activo.db)
          .eq('activo', true));

  /// Solicitudes pendientes en tiempo real. .stream() admite un solo .eq():
  /// el filtro fino y el orden sobre DateTime los hace el repositorio.
  Stream<List<Map<String, dynamic>>> pendientes() => _tabla
      .stream(primaryKey: ['id'])
      .eq('estado', EstadoCuenta.pendiente.db)
      .order('created_at', ascending: false)
      .traducirErrores(falloDesdeSupabase);

  /// aprobado_en NO se envía: lo sella el trigger con la hora del servidor.
  Future<void> aprobar(
    String uid, {
    required RolUsuario rol,
    required String plantaId,
    required UsuarioRef aprobadoPor,
  }) =>
      traducirSupabase(() => _tabla.update({
            'estado': EstadoCuenta.activo.db,
            'rol': rol.db,
            'planta_id': plantaId,
            'aprobado_por': refAJson(aprobadoPor),
          }).eq('id', uid));

  Future<void> rechazar(String uid, UsuarioRef aprobadoPor) =>
      traducirSupabase(() => _tabla.update({
            'estado': EstadoCuenta.rechazado.db,
            'aprobado_por': refAJson(aprobadoPor),
          }).eq('id', uid));
}
