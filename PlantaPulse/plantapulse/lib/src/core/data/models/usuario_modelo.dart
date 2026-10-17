// lib/src/core/data/models/usuario_modelo.dart
import '../../domain/entities/usuario.dart';
import '../json_helpers.dart';

/// UsuarioRef viaja dentro de columnas jsonb (creado_por, asignado_a,
/// aprobado_por...). Dentro del jsonb las claves van en camelCase:
/// {"uid": ..., "nombre": ..., "fotoUrl": ...}.
class UsuarioRefModelo extends UsuarioRef {
  const UsuarioRefModelo({
    required super.uid,
    required super.nombre,
    super.fotoUrl,
  });

  factory UsuarioRefModelo.desdeEntidad(UsuarioRef r) =>
      UsuarioRefModelo(uid: r.uid, nombre: r.nombre, fotoUrl: r.fotoUrl);

  factory UsuarioRefModelo.fromJson(Map<String, dynamic> m) => UsuarioRefModelo(
        uid: texto(m['uid']),
        nombre: texto(m['nombre'], 'Sin nombre'),
        fotoUrl: textoOpcional(m['fotoUrl']),
      );

  /// null si la columna jsonb viene vacía.
  static UsuarioRefModelo? fromJsonOpcional(dynamic m) =>
      m is Map ? UsuarioRefModelo.fromJson(mapa(m)) : null;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'nombre': nombre,
        'fotoUrl': fotoUrl,
      };
}

/// Atajo para serializar un UsuarioRef de la entidad.
Map<String, dynamic> refAJson(UsuarioRef r) =>
    UsuarioRefModelo.desdeEntidad(r).toJson();

Map<String, dynamic>? refAJsonOpcional(UsuarioRef? r) =>
    r == null ? null : refAJson(r);

/// Fila de la tabla 'usuarios'. El id ES el uid de auth.users.
class UsuarioModelo extends Usuario {
  const UsuarioModelo({
    required super.uid,
    required super.nombre,
    required super.email,
    required super.rol,
    super.especialidad,
    required super.plantaId,
    super.zonasAsignadas,
    super.fotoUrl,
    super.turno,
    super.fcmToken,
    super.activo,
    required super.createdAt,
    super.estado,
    super.aprobadoPor,
    super.aprobadoEn,
  });

  factory UsuarioModelo.desdeEntidad(Usuario u) => UsuarioModelo(
        uid: u.uid,
        nombre: u.nombre,
        email: u.email,
        rol: u.rol,
        especialidad: u.especialidad,
        plantaId: u.plantaId,
        zonasAsignadas: u.zonasAsignadas,
        fotoUrl: u.fotoUrl,
        turno: u.turno,
        fcmToken: u.fcmToken,
        activo: u.activo,
        createdAt: u.createdAt,
        estado: u.estado,
        aprobadoPor: u.aprobadoPor,
        aprobadoEn: u.aprobadoEn,
      );

  factory UsuarioModelo.fromJson(Map<String, dynamic> j) => UsuarioModelo(
        uid: texto(j['id']),
        nombre: texto(j['nombre'], 'Sin nombre'),
        email: texto(j['email']),
        rol: RolUsuarioX.desdeDb(j['rol']),
        especialidad: texto(j['especialidad']),
        plantaId: texto(j['planta_id']),
        zonasAsignadas: listaTexto(j['zonas_asignadas']),
        fotoUrl: textoOpcional(j['foto_url']),
        turno: texto(j['turno']),
        fcmToken: textoOpcional(j['fcm_token']),
        activo: booleano(j['activo'], true),
        createdAt: fecha(j['created_at']),
        estado: EstadoCuentaX.desdeDb(textoOpcional(j['estado'])),
        aprobadoPor: UsuarioRefModelo.fromJsonOpcional(j['aprobado_por']),
        aprobadoEn: fechaOpcional(j['aprobado_en']),
      );

  /// created_at y aprobado_en no se envían: los ponen los triggers.
  Map<String, dynamic> toJson() => {
        'id': uid,
        'nombre': nombre,
        'email': email,
        'rol': rol.db,
        'especialidad': especialidad,
        'planta_id': plantaId,
        'zonas_asignadas': zonasAsignadas,
        'foto_url': fotoUrl,
        'turno': turno,
        'fcm_token': fcmToken,
        'activo': activo,
        'estado': estado.db,
        'aprobado_por': refAJsonOpcional(aprobadoPor),
      };
}
