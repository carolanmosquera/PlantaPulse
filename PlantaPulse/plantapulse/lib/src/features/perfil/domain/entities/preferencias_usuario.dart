import 'package:equatable/equatable.dart';

enum Preferencia {
  notificacionesPush,
  alertasMantenimiento,
  soloCriticas,
  modoOscuro,
  modoOffline,
}

/// Preferencias personales; no conceden permisos ni activan servicios.
class PreferenciasUsuario extends Equatable {
  final bool notificacionesPush;
  final bool alertasMantenimiento;
  final bool soloCriticas;
  final bool modoOscuro;
  final bool modoOffline;

  const PreferenciasUsuario({
    this.notificacionesPush = true,
    this.alertasMantenimiento = true,
    this.soloCriticas = false,
    this.modoOscuro = false,
    this.modoOffline = false,
  });

  bool valor(Preferencia campo) => switch (campo) {
    Preferencia.notificacionesPush => notificacionesPush,
    Preferencia.alertasMantenimiento => alertasMantenimiento,
    Preferencia.soloCriticas => soloCriticas,
    Preferencia.modoOscuro => modoOscuro,
    Preferencia.modoOffline => modoOffline,
  };

  PreferenciasUsuario cambiar(Preferencia campo, bool nuevo) =>
      PreferenciasUsuario(
        notificacionesPush: campo == Preferencia.notificacionesPush
            ? nuevo
            : notificacionesPush,
        alertasMantenimiento: campo == Preferencia.alertasMantenimiento
            ? nuevo
            : alertasMantenimiento,
        soloCriticas: campo == Preferencia.soloCriticas ? nuevo : soloCriticas,
        modoOscuro: campo == Preferencia.modoOscuro ? nuevo : modoOscuro,
        modoOffline: campo == Preferencia.modoOffline ? nuevo : modoOffline,
      );

  @override
  List<Object?> get props => [
    notificacionesPush,
    alertasMantenimiento,
    soloCriticas,
    modoOscuro,
    modoOffline,
  ];
}
