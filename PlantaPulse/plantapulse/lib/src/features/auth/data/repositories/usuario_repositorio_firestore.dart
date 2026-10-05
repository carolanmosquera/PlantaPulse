// lib/src/features/auth/data/repositories/usuario_repositorio_firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/data.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';

/// Habla SOLO con la colección 'usuarios' de Firestore.
/// No sabe nada de contraseñas ni de Firebase Auth.
class UsuarioRepositorioFirestore implements UsuarioRepositorio {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('usuarios');

  /// Crea el documento del perfil. El ID del documento es el uid de Auth.
  @override
  Future<void> crear(Usuario usuario) => traducirFirestore(
      () => _col.doc(usuario.uid).set(usuario.aFirestore()));

  /// Lee el perfil una sola vez. Devuelve null si no existe.
  @override
  Future<Usuario?> obtener(String uid) => traducirFirestore(() async {
        final doc = await _col.doc(uid).get();
        if (!doc.exists) return null;
        return usuarioDesdeFirestore(doc);
      });

  /// Escucha los cambios del perfil en tiempo real.
  @override
  Stream<Usuario?> escuchar(String uid) => _col
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? usuarioDesdeFirestore(doc) : null)
      .traducirErrores(falloDesdeFirestore);

  /// Actualiza solo los campos que cambian, no el documento completo.
  /// Usar set() aquí borraría los campos que no mandes.
  @override
  Future<void> actualizar(String uid, Map<String, dynamic> cambios) =>
      traducirFirestore(() => _col.doc(uid).update(cambios));

  @override
  Future<void> guardarTokenPush(String uid, String token) =>
      actualizar(uid, {'fcmToken': token});

  /// Los técnicos de una planta, para el selector de responsable
  /// en la pantalla de crear orden (paso 2).
  /// Solo cuentas aprobadas: un técnico rechazado no puede recibir órdenes.
  /// Todos los filtros son de igualdad, así que no necesita índice;
  /// el orden por nombre se hace aquí por la misma razón.
  @override
  Future<List<Usuario>> tecnicosDePlanta(String plantaId) =>
      traducirFirestore(() async {
        final snap = await _col
            .where('plantaId', isEqualTo: plantaId)
            .where('rol', isEqualTo: RolUsuario.tecnico.db)
            .where('estado', isEqualTo: EstadoCuenta.activo.db)
            .where('activo', isEqualTo: true)
            .get();
        return snap.docs.map(usuarioDesdeFirestore).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
      });

  // ── Aprobación de cuentas (admin) ──────────────────────────────

  /// Solicitudes pendientes de aprobación, para la bandeja del admin.
  /// No se filtra por planta: al registrarse el usuario aún no tiene planta.
  @override
  Stream<List<Usuario>> solicitudesPendientes() => _col
      .where('estado', isEqualTo: EstadoCuenta.pendiente.db)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(usuarioDesdeFirestore).toList())
      .traducirErrores(falloDesdeFirestore);

  @override
  Future<void> aprobar(
    String uid, {
    required RolUsuario rol,
    required String plantaId,
    required UsuarioRef aprobadoPor,
  }) =>
      actualizar(uid, {
        'estado': EstadoCuenta.activo.db,
        'rol': rol.db,
        'plantaId': plantaId,
        'aprobadoPor': aprobadoPor.aMapa(),
        'aprobadoEn': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> rechazar(String uid, UsuarioRef aprobadoPor) =>
      actualizar(uid, {
        'estado': EstadoCuenta.rechazado.db,
        'aprobadoPor': aprobadoPor.aMapa(),
        'aprobadoEn': FieldValue.serverTimestamp(),
      });
}
