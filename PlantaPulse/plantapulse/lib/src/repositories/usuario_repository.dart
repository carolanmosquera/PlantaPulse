// lib/src/repositories/usuario_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

/// Habla SOLO con la colección 'usuarios' de Firestore.
/// No sabe nada de contraseñas ni de Firebase Auth.
class UsuarioRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('usuarios');

  /// Crea el documento del perfil. El ID del documento es el uid de Auth.
  Future<void> crear(Usuario usuario) =>
      _col.doc(usuario.uid).set(usuario.aFirestore());

  /// Lee el perfil una sola vez. Devuelve null si no existe.
  Future<Usuario?> obtener(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return Usuario.desdeFirestore(doc);
  }

  /// Escucha los cambios del perfil en tiempo real.
  Stream<Usuario?> escuchar(String uid) => _col.doc(uid).snapshots().map(
        (doc) => doc.exists ? Usuario.desdeFirestore(doc) : null,
      );

  /// Actualiza solo los campos que cambian, no el documento completo.
  /// Usar set() aquí borraría los campos que no mandes.
  Future<void> actualizar(String uid, Map<String, dynamic> cambios) =>
      _col.doc(uid).update(cambios);

  Future<void> guardarTokenPush(String uid, String token) =>
      actualizar(uid, {'fcmToken': token});

  /// Los técnicos de una planta, para el selector de responsable
  /// en la pantalla de crear orden (paso 2).
  Future<List<Usuario>> tecnicosDePlanta(String plantaId) async {
    final snap = await _col
        .where('plantaId', isEqualTo: plantaId)
        .where('rol', isEqualTo: 'tecnico')
        .where('activo', isEqualTo: true)
        .get();
    return snap.docs.map(Usuario.desdeFirestore).toList();
  }

  // ── Aprobación de cuentas (admin) ──────────────────────────────

  /// Solicitudes pendientes de aprobación, para la bandeja del admin.
  /// No se filtra por planta: al registrarse el usuario aún no tiene planta.
  Stream<List<Usuario>> solicitudesPendientes() => _col
      .where('estado', isEqualTo: EstadoCuenta.pendiente.db)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Usuario.desdeFirestore).toList());

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

  Future<void> rechazar(String uid, UsuarioRef aprobadoPor) =>
      actualizar(uid, {
        'estado': EstadoCuenta.rechazado.db,
        'aprobadoPor': aprobadoPor.aMapa(),
        'aprobadoEn': FieldValue.serverTimestamp(),
      });
}