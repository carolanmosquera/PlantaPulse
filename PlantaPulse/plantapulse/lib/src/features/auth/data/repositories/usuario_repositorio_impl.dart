// lib/src/features/auth/data/repositories/usuario_repositorio_impl.dart
import 'dart:async';
import '../../../../core/data/models/usuario_modelo.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';
import '../datasources/usuario_fuente_supabase.dart';

/// Implementación del contrato. No sabe qué base de datos hay debajo:
/// traduce filas a entidades y hace lo que ocurre en memoria (orden por
/// nombre, la bandeja de solicitudes ya decididas).
class UsuarioRepositorioImpl implements UsuarioRepositorio {
  final UsuarioFuenteSupabase _fuente;

  UsuarioRepositorioImpl(this._fuente);

  /// Solicitudes que este admin ya aprobó o rechazó en esta sesión.
  /// Ver solicitudesPendientes().
  final Set<String> _decididas = {};
  final _avisoDecision = StreamController<void>.broadcast();

  @override
  Future<void> crear(Usuario usuario) =>
      _fuente.insertar(UsuarioModelo.desdeEntidad(usuario).toJson());

  @override
  Future<Usuario?> obtener(String uid) async {
    final fila = await _fuente.obtener(uid);
    return fila == null ? null : UsuarioModelo.fromJson(fila);
  }

  @override
  Stream<Usuario?> escuchar(String uid) => _fuente.escuchar(uid).map(
      (filas) => filas.isEmpty ? null : UsuarioModelo.fromJson(filas.first));

  @override
  Future<void> actualizar(String uid, Map<String, dynamic> cambios) =>
      _fuente.actualizar(uid, cambios);

  @override
  Future<void> guardarTokenPush(String uid, String token) =>
      actualizar(uid, {'fcmToken': token});

  /// Los técnicos de una planta, para el selector de responsable.
  /// Solo cuentas aprobadas: un técnico rechazado no puede recibir órdenes.
  /// El orden por nombre se hace en Dart, igual que antes.
  @override
  Future<List<Usuario>> tecnicosDePlanta(String plantaId) async {
    final filas = await _fuente.tecnicosDePlanta(plantaId);
    return filas.map(UsuarioModelo.fromJson).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

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
        filas = _fuente.pendientes().listen(
              (datos) {
                ultima = datos.map(UsuarioModelo.fromJson).toList();
                salida.add(visibles());
              },
              // La fuente ya entrega el error traducido a FalloApp
              onError: (Object e, StackTrace st) => salida.addError(e, st),
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

  @override
  Future<void> aprobar(
    String uid, {
    required RolUsuario rol,
    required String plantaId,
    required UsuarioRef aprobadoPor,
  }) async {
    await _fuente.aprobar(uid,
        rol: rol, plantaId: plantaId, aprobadoPor: aprobadoPor);
    _marcarDecidida(uid);
  }

  @override
  Future<void> rechazar(String uid, UsuarioRef aprobadoPor) async {
    await _fuente.rechazar(uid, aprobadoPor);
    _marcarDecidida(uid);
  }

  void _marcarDecidida(String uid) {
    _decididas.add(uid);
    _avisoDecision.add(null);
  }
}
