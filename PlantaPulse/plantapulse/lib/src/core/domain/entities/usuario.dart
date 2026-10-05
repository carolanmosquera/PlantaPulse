// lib/src/core/domain/entities/usuario.dart

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

  factory UsuarioRef.desdeUsuario(Usuario u) => UsuarioRef(
        uid: u.uid,
        nombre: u.nombre,
        fotoUrl: u.fotoUrl,
      );

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