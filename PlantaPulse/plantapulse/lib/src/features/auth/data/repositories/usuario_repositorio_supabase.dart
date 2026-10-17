// lib/src/features/auth/data/repositories/usuario_repositorio_supabase.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/data.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';

/// Habla SOLO con la tabla 'usuarios'. No sabe nada de contraseñas.
///
/// Regla: los update() NO llevan .select(). Pedir la fila de vuelta
/// exige poder leerla, y el admin no puede leer el perfil que acaba de
/// aprobar si quedó en otra planta: la actualización fallaría.
class UsuarioRepositorioSupabase implements UsuarioRepositorio {
  final SupabaseClient _db;

  UsuarioRepositorioSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('usuarios');

  /// Solicitudes que este admin ya aprobó o rechazó en esta sesión.
  /// Ver solicitudesPendientes().
  final Set<String> _decididas = {};
  final _avisoDecision = StreamController<void>.broadcast();

  /// Crea el perfil. El id es el uid de auth.users.
  /// created_at lo pone el trigger con la hora del servidor.
  @override
  Future<void> crear(Usuario usuario) => traducirSupabase(
      () => _tabla.insert(UsuarioModelo.desdeEntidad(usuario).toJson()));

  /// Lee el perfil una sola vez. Devuelve null si no existe (o si RLS
  /// no deja verlo: en Postgres eso no es un error, solo no hay filas).
  @override
  Future<Usuario?> obtener(String uid) => traducirSupabase(() async {
        final fila = await _tabla.select().eq('id', uid).maybeSingle();
        return fila == null ? null : UsuarioModelo.fromJson(fila);
      });

  /// Escucha los cambios del perfil en tiempo real.
  @override
  Stream<Usuario?> escuchar(String uid) => _tabla
      .stream(primaryKey: ['id'])
      .eq('id', uid)
      .map((filas) => filas.isEmpty ? null : UsuarioModelo.fromJson(filas.first))
      .traducirErrores(falloDesdeSupabase);

  /// Actualiza solo los campos que cambian. Las claves son los nombres
  /// de las propiedades de la entidad (fcmToken); aquí se traducen a
  /// columnas (fcm_token). Qué columnas puede tocar cada quien lo decide
  /// el trigger proteger_usuarios.
  @override
  Future<void> actualizar(String uid, Map<String, dynamic> cambios) =>
      traducirSupabase(() => _tabla.update({
            for (final c in cambios.entries) aColumna(c.key): _valor(c.value),
          }).eq('id', uid));

  static Object? _valor(Object? v) => switch (v) {
        DateTime f => aIso(f),
        UsuarioRef r => refAJson(r),
        _ => v,
      };

  @override
  Future<void> guardarTokenPush(String uid, String token) =>
      actualizar(uid, {'fcmToken': token});

  /// Los técnicos de una planta, para el selector de responsable
  /// en la pantalla de crear orden (paso 2).
  /// Solo cuentas aprobadas: un técnico rechazado no puede recibir órdenes.
  /// El orden por nombre se hace en Dart, igual que antes.
  @override
  Future<List<Usuario>> tecnicosDePlanta(String plantaId) =>
      traducirSupabase(() async {
        final filas = await _tabla
            .select()
            .eq('planta_id', plantaId)
            .eq('rol', RolUsuario.tecnico.db)
            .eq('estado', EstadoCuenta.activo.db)
            .eq('activo', true);
        return filas.map(UsuarioModelo.fromJson).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
      });

  // ── Aprobación de cuentas (admin) ──────────────────────────────

  /// Solicitudes pendientes en tiempo real, para la bandeja del admin.
  ///
  /// Cuando el admin aprueba a alguien de OTRA planta, ese perfil deja de
  /// ser visible para él: RLS no le manda el evento de cambio y el stream
  /// lo dejaría en la lista para siempre. Por eso, al aprobar o rechazar,
  /// el uid se guarda en _decididas y se quita de la lista en memoria.
  ///
  /// Además se filtra estado == pendiente en Dart: si el evento sí llega
  /// (misma planta), el stream de Supabase reemplaza la fila en la lista
  /// en lugar de sacarla.
  @override
  Stream<List<Usuario>> solicitudesPendientes() {
    late final StreamController<List<Usuario>> salida;
    StreamSubscription<List<Map<String, dynamic>>>? filas;
    StreamSubscription<void>? decisiones;
    var ultima = const <Usuario>[];

    List<Usuario> visibles() => ultima
        .where((u) =>
            u.estado == EstadoCuenta.pendiente && !_decididas.contains(u.uid))
        .toList()
      // El orden en Dart: el stream de Supabase compara fechas como texto
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    salida = StreamController<List<Usuario>>(
      onListen: () {
        filas = _tabla
            .stream(primaryKey: ['id'])
            .eq('estado', EstadoCuenta.pendiente.db)
            .order('created_at', ascending: false)
            .listen(
              (datos) {
                ultima = datos.map(UsuarioModelo.fromJson).toList();
                salida.add(visibles());
              },
              onError: (Object e, StackTrace st) =>
                  salida.addError(falloDesdeSupabase(e), st),
            );
        decisiones = _avisoDecision.stream.listen((_) => salida.add(visibles()));
      },
      onCancel: () async {
        await filas?.cancel();
        await decisiones?.cancel();
      },
    );
    return salida.stream;
  }

  /// aprobado_en NO se envía: lo sella el trigger con la hora del servidor.
  @override
  Future<void> aprobar(
    String uid, {
    required RolUsuario rol,
    required String plantaId,
    required UsuarioRef aprobadoPor,
  }) async {
    await traducirSupabase(() => _tabla.update({
          'estado': EstadoCuenta.activo.db,
          'rol': rol.db,
          'planta_id': plantaId,
          'aprobado_por': refAJson(aprobadoPor),
        }).eq('id', uid));
    _marcarDecidida(uid);
  }

  @override
  Future<void> rechazar(String uid, UsuarioRef aprobadoPor) async {
    await traducirSupabase(() => _tabla.update({
          'estado': EstadoCuenta.rechazado.db,
          'aprobado_por': refAJson(aprobadoPor),
        }).eq('id', uid));
    _marcarDecidida(uid);
  }

  void _marcarDecidida(String uid) {
    _decididas.add(uid);
    _avisoDecision.add(null);
  }
}
