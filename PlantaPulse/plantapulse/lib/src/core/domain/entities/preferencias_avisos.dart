// lib/src/core/domain/entities/preferencias_avisos.dart

/// Qué avisos quiere recibir el usuario (KAN-100). Se guarda en su perfil
/// (usuarios.preferencias_avisos) para que sobreviva al cierre de la app
/// y para que quien envía las notificaciones pueda respetarlas.
class PreferenciasAvisos {
  /// Notificaciones push en este dispositivo. Apagado = el token se borra
  /// del perfil y el teléfono deja de recibir cualquier aviso.
  final bool push;

  /// Avisos de estado de las órdenes de trabajo.
  final bool mantenimiento;

  /// Solo avisos de prioridad alta/urgente.
  final bool soloCriticas;

  const PreferenciasAvisos({
    this.push = true,
    this.mantenimiento = true,
    this.soloCriticas = false,
  });

  PreferenciasAvisos copyWith({
    bool? push,
    bool? mantenimiento,
    bool? soloCriticas,
  }) =>
      PreferenciasAvisos(
        push: push ?? this.push,
        mantenimiento: mantenimiento ?? this.mantenimiento,
        soloCriticas: soloCriticas ?? this.soloCriticas,
      );

  /// Las claves son las mismas que lee el servidor al enviar.
  Map<String, dynamic> toJson() => {
        'push': push,
        'mantenimiento': mantenimiento,
        'soloCriticas': soloCriticas,
      };

  /// Una clave que falte vale su valor por defecto: un perfil viejo, sin
  /// preferencias guardadas, recibe todo como antes.
  factory PreferenciasAvisos.fromJson(Object? json) {
    final m = json is Map ? json : const {};
    bool leer(String clave, bool porDefecto) {
      final v = m[clave];
      return v is bool ? v : porDefecto;
    }

    return PreferenciasAvisos(
      push: leer('push', true),
      mantenimiento: leer('mantenimiento', true),
      soloCriticas: leer('soloCriticas', false),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PreferenciasAvisos &&
      other.push == push &&
      other.mantenimiento == mantenimiento &&
      other.soloCriticas == soloCriticas;

  @override
  int get hashCode => Object.hash(push, mantenimiento, soloCriticas);
}
