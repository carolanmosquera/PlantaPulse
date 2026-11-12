// lib/src/core/domain/repositories/push_repositorio.dart

/// Notificaciones push del dispositivo (KAN-96). Está en core porque la
/// sesión, el perfil y los avisos la van a necesitar.
///
/// No sabe qué servicio hay detrás (hoy Firebase Cloud Messaging). En web
/// y en las pruebas no hay push: [activar] devuelve null y los streams no
/// emiten nada.
abstract class PushRepositorio {
  /// Pide permiso para mostrar notificaciones y devuelve el token del
  /// dispositivo. Devuelve null si el usuario no da permiso o si la
  /// plataforma no tiene push.
  Future<String?> activar();

  /// El servicio cambia el token de vez en cuando (reinstalación, datos
  /// borrados...). Cada token nuevo llega por aquí.
  Stream<String> get tokenRenovado;

  /// Invalida el token del dispositivo: deja de recibir notificaciones.
  Future<void> desactivar();

  /// Si la app estaba cerrada y se abrió al tocar una notificación,
  /// el id de la orden que traía. Solo se puede leer una vez.
  Future<String?> ordenQueAbrioLaApp();

  /// Ids de las órdenes de las notificaciones tocadas con la app en
  /// segundo plano.
  Stream<String> get ordenesTocadas;
}
