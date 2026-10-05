// lib/src/features/ordenes/data/repositories/orden_repositorio_firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/data.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';
import '../../../../core/errors/fallos.dart';

/// Habla SOLO con la colección 'ordenes' de Firestore.
///
/// Regla: TODA consulta lleva where('plantaId'). Las reglas de seguridad
/// lo exigen, y una consulta sin ese filtro falla completa aunque los
/// documentos sí fueran legibles uno por uno.
class OrdenRepositorioFirestore implements OrdenRepositorio {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('ordenes');

  /// Los errores del stream llegan al Bloc con un mensaje para el aviso.
  static FalloApp _falloDeLectura(Object e) => falloDesdeFirestore(
        e,
        permisos: 'No tienes permiso para ver las órdenes de esta planta.',
        sinIndice: 'Falta un índice en Firestore para esta consulta.',
        sinConexion: 'Sin conexión. Se muestran los últimos datos recibidos.',
        generico: 'No se pudieron actualizar las órdenes.',
      );

  /// Feed de la planta en tiempo real, las más nuevas primero.
  /// Índices: plantaId + createdAt, y plantaId + estado + createdAt.
  @override
  Stream<List<Orden>> deLaPlanta(String plantaId, {EstadoOrden? estado}) {
    Query<Map<String, dynamic>> consulta =
        _col.where('plantaId', isEqualTo: plantaId);
    if (estado != null) {
      consulta = consulta.where('estado', isEqualTo: estado.db);
    }
    return consulta
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ordenDesdeFirestore).toList())
        .traducirErrores(_falloDeLectura);
  }

  /// "Mis Tareas": las órdenes de un técnico, la que vence primero arriba.
  /// Índice: plantaId + asignadoAUid + fechaLimite.
  @override
  Stream<List<Orden>> asignadasA(String uid, String plantaId) => _col
      .where('plantaId', isEqualTo: plantaId)
      .where('asignadoAUid', isEqualTo: uid)
      .orderBy('fechaLimite')
      .snapshots()
      .map((snap) => snap.docs.map(ordenDesdeFirestore).toList())
      .traducirErrores(_falloDeLectura);

  /// Crea la orden con un ID generado por Firestore y lo devuelve.
  /// Las fechas de creación y actividad las pone el servidor, no el
  /// reloj del teléfono (que puede estar mal configurado).
  @override
  Future<String> crear(Orden orden) => traducirFirestore(() async {
        final datos = orden.aFirestore()
          ..['createdAt'] = FieldValue.serverTimestamp()
          ..['ultimaActividad'] = FieldValue.serverTimestamp();
        final ref = await _col.add(datos);
        return ref.id;
      });

  @override
  Future<void> actualizarEstado(String ordenId, EstadoOrden estado) =>
      traducirFirestore(() => _col.doc(ordenId).update({
            'estado': estado.db,
            'ultimaActividad': FieldValue.serverTimestamp(),
          }));
}
