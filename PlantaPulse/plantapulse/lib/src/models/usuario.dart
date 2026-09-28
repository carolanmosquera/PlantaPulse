// lib/src/models/usuario.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

enum RolUsuario { admin, supervisor, tecnico }

extension RolUsuarioX on RolUsuario {
  String get etiqueta => switch (this) {
        RolUsuario.admin      => 'Administrador',
        RolUsuario.supervisor => 'Supervisor de Planta',
        RolUsuario.tecnico    => 'Técnico de Mantenimiento',
      };

  /// Valor que se guarda en Firestore. Siempre texto, nunca el índice del enum:
  /// si mañana agregas un rol en medio, los índices se corren y los datos
  /// viejos quedarían mal interpretados.
  String get db => switch (this) {
        RolUsuario.admin      => 'admin',
        RolUsuario.supervisor => 'supervisor',
        RolUsuario.tecnico    => 'tecnico',
      };

  bool get esAdmin => this == RolUsuario.admin;
  bool get esSupervisor => this == RolUsuario.supervisor;

  static RolUsuario desdeDb(String? valor) => switch (valor) {
        'admin'      => RolUsuario.admin,
        'supervisor' => RolUsuario.supervisor,
        _            => RolUsuario.tecnico,
      };
}

/// Estado de la cuenta dentro del flujo de aprobación.
/// Al registrarse queda 'pendiente' hasta que un admin la apruebe o rechace.
enum EstadoCuenta { pendiente, activo, rechazado }

extension EstadoCuentaX on EstadoCuenta {
  String get etiqueta => switch (this) {
        EstadoCuenta.pendiente => 'Pendiente de aprobación',
        EstadoCuenta.activo    => 'Activo',
        EstadoCuenta.rechazado => 'Acceso denegado',
      };

  /// Valor que se guarda en Firestore (texto, nunca el índice).
  String get db => switch (this) {
        EstadoCuenta.pendiente => 'pendiente',
        EstadoCuenta.activo    => 'activo',
        EstadoCuenta.rechazado => 'rechazado',
      };

  /// Solo una cuenta activa puede entrar al feed.
  bool get puedeEntrar => this == EstadoCuenta.activo;

  static EstadoCuenta desdeDb(String? valor) => switch (valor) {
        'activo'    => EstadoCuenta.activo,
        'rechazado' => EstadoCuenta.rechazado,
        _           => EstadoCuenta.pendiente,
      };
}

/// Referencia corta a un usuario, para DENORMALIZAR.
///
/// Se copia dentro de la orden y del reporte para que el feed pueda mostrar
/// "Creado por Carlos Mendoza" sin hacer una consulta extra por cada tarjeta.
/// Firestore no tiene JOIN: esta es la forma de evitarlo.
class UsuarioRef {
  final String uid;
  final String nombre;
  final String? fotoUrl;

  const UsuarioRef({
    required this.uid,
    required this.nombre,
    this.fotoUrl,
  });

  factory UsuarioRef.desdeMapa(Map<String, dynamic> m) => UsuarioRef(
        uid: texto(m['uid']),
        nombre: texto(m['nombre'], 'Sin nombre'),
        fotoUrl: textoOpcional(m['fotoUrl']),
      );

  factory UsuarioRef.desdeUsuario(Usuario u) => UsuarioRef(
        uid: u.uid,
        nombre: u.nombre,
        fotoUrl: u.fotoUrl,
      );

  Map<String, dynamic> aMapa() => {
        'uid': uid,
        'nombre': nombre,
        'fotoUrl': fotoUrl,
      };

  /// Inicial para el CircleAvatar cuando no hay foto
  String get inicial => nombre.isEmpty ? '?' : nombre.trim()[0].toUpperCase();
}

class Usuario {
  final String uid;              // el mismo uid de Firebase Auth
  final String nombre;
  final String email;
  final RolUsuario rol;
  final String especialidad;     // mecánico, eléctrico, electrónico...
  final String plantaId;
  final List<String> zonasAsignadas;
  final String? fotoUrl;
  final String turno;            // matutino, vespertino, nocturno
  final String? fcmToken;        // para notificaciones push
  final bool activo;
  final DateTime createdAt;
  final EstadoCuenta estado;     // flujo de aprobación por el admin
  final UsuarioRef? aprobadoPor; // admin que aprobó o rechazó
  final DateTime? aprobadoEn;

  const Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    this.especialidad = '',
    required this.plantaId,
    this.zonasAsignadas = const [],
    this.fotoUrl,
    this.turno = '',
    this.fcmToken,
    this.activo = true,
    required this.createdAt,
    this.estado = EstadoCuenta.pendiente,
    this.aprobadoPor,
    this.aprobadoEn,
  });

  factory Usuario.desdeFirestore(DocumentSnapshot doc) {
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
          : UsuarioRef.desdeMapa(mapa(d['aprobadoPor'])),
      aprobadoEn: fechaOpcional(d['aprobadoEn']),
    );
  }

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

  UsuarioRef get ref => UsuarioRef.desdeUsuario(this);

  bool get puedeEntrar => estado.puedeEntrar;

  Usuario copyWith({
    String? nombre,
    RolUsuario? rol,
    String? plantaId,
    EstadoCuenta? estado,
    UsuarioRef? aprobadoPor,
    String? especialidad,
    List<String>? zonasAsignadas,
    String? fotoUrl,
    String? turno,
    String? fcmToken,
    bool? activo,
  }) =>
      Usuario(
        uid: uid,
        nombre: nombre ?? this.nombre,
        email: email,
        rol: rol ?? this.rol,
        especialidad: especialidad ?? this.especialidad,
        plantaId: plantaId ?? this.plantaId,
        zonasAsignadas: zonasAsignadas ?? this.zonasAsignadas,
        fotoUrl: fotoUrl ?? this.fotoUrl,
        turno: turno ?? this.turno,
        fcmToken: fcmToken ?? this.fcmToken,
        activo: activo ?? this.activo,
        createdAt: createdAt,
        estado: estado ?? this.estado,
        aprobadoPor: aprobadoPor ?? this.aprobadoPor,
        aprobadoEn: aprobadoEn,
      );
}