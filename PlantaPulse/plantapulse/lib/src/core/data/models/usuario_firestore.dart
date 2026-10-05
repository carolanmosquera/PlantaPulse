// lib/src/core/data/models/usuario_firestore.dart
// TODO fase B: mover a data/models como UsuarioModelo con fromJson/toJson.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/usuario.dart';
import '../firestore_helpers.dart';

UsuarioRef usuarioRefDesdeMapa(Map<String, dynamic> m) => UsuarioRef(
      uid: texto(m['uid']),
      nombre: texto(m['nombre'], 'Sin nombre'),
      fotoUrl: textoOpcional(m['fotoUrl']),
    );

extension UsuarioRefMapa on UsuarioRef {
  Map<String, dynamic> aMapa() => {
        'uid': uid,
        'nombre': nombre,
        'fotoUrl': fotoUrl,
      };
}

Usuario usuarioDesdeFirestore(DocumentSnapshot doc) {
  final d = mapa(doc.data());
  return Usuario(
    uid: doc.id,                          // el ID del documento ES el uid
    nombre: texto(d['nombre'], 'Sin nombre'),
    email: texto(d['email']),
    rol: RolUsuarioX.desdeDb(d['rol']),
    especialidad: texto(d['especialidad']),
    plantaId: texto(d['plantaId']),
    zonasAsignadas: listaTexto(d['zonasAsignadas']),
    fotoUrl: textoOpcional(d['fotoUrl']),
    turno: texto(d['turno']),
    fcmToken: textoOpcional(d['fcmToken']),
    activo: booleano(d['activo'], true),
    createdAt: fecha(d['createdAt']),
    estado: EstadoCuentaX.desdeDb(textoOpcional(d['estado'])),
    aprobadoPor: d['aprobadoPor'] == null
        ? null
        : usuarioRefDesdeMapa(mapa(d['aprobadoPor'])),
    aprobadoEn: fechaOpcional(d['aprobadoEn']),
  );
}

extension UsuarioFirestore on Usuario {
  Map<String, dynamic> aFirestore() => {
        // El uid NO se guarda como campo: ya es el ID del documento
        'nombre': nombre,
        'email': email,
        'rol': rol.db,
        'especialidad': especialidad,
        'plantaId': plantaId,
        'zonasAsignadas': zonasAsignadas,
        'fotoUrl': fotoUrl,
        'turno': turno,
        'fcmToken': fcmToken,
        'activo': activo,
        'createdAt': Timestamp.fromDate(createdAt),
        'estado': estado.db,
        'aprobadoPor': aprobadoPor?.aMapa(),
        'aprobadoEn': aprobadoEn == null ? null : Timestamp.fromDate(aprobadoEn!),
      };
}
