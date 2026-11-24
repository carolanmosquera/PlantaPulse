import '../../domain/entities/preferencias_usuario.dart';

class PreferenciasModelo {
  static String clave(Preferencia campo) => switch (campo) {
    Preferencia.notificacionesPush => 'notificaciones_push',
    Preferencia.alertasMantenimiento => 'alertas_mantenimiento',
    Preferencia.soloCriticas => 'solo_criticas',
    Preferencia.modoOscuro => 'modo_oscuro',
    Preferencia.modoOffline => 'modo_offline',
  };

  static PreferenciasUsuario desdeJson(Map<String, dynamic> json) {
    bool leer(String clave, bool inicial) =>
        json[clave] is bool ? json[clave] as bool : inicial;
    return PreferenciasUsuario(
      notificacionesPush: leer('notificaciones_push', true),
      alertasMantenimiento: leer('alertas_mantenimiento', true),
      soloCriticas: leer('solo_criticas', false),
      modoOscuro: leer('modo_oscuro', false),
      modoOffline: leer('modo_offline', false),
    );
  }
}
