// lib/src/features/notificaciones/data/datasources/push_fuente_fcm.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// El único lugar que habla con Firebase Cloud Messaging.
///
/// Usa el token clásico de FCM (getToken / onTokenRefresh / deleteToken).
/// firebase_messaging 17 lo marca como obsoleto a favor de register() y el
/// Installation ID, pero el token es lo que entiende la API HTTP v1 de FCM
/// con la que se envían las notificaciones (y la consola de Firebase para
/// las pruebas), así que se usa a propósito.
///
/// Por ahora solo Android tiene push: su configuración sale de
/// android/app/google-services.json. En web, iOS (todavía sin
/// GoogleService-Info.plist) y en las pruebas, [inicializar] no hace nada
/// y todos los métodos responden como si no hubiera push.
class PushFuenteFcm {
  /// Se marca en [inicializar]. Mientras sea false no se toca Firebase:
  /// así las pruebas y la versión web funcionan sin configurarlo.
  static bool _listo = false;

  /// Se llama una sola vez en main(), antes de runApp. Si Firebase falla,
  /// la app sigue funcionando, solo que sin notificaciones.
  static Future<void> inicializar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Firebase.initializeApp();
      _listo = true;
    } catch (e) {
      debugPrint('Push desactivado: Firebase no se pudo iniciar ($e)');
    }
  }

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  /// Pide el permiso (en Android 13+ aparece el cuadro del sistema) y
  /// devuelve el token, o null si no hay permiso.
  Future<String?> pedirPermisoYToken() async {
    if (!_listo) return null;
    final permiso = await _fcm.requestPermission();
    final aceptado =
        permiso.authorizationStatus == AuthorizationStatus.authorized ||
        permiso.authorizationStatus == AuthorizationStatus.provisional;
    if (!aceptado) return null;
    // ignore: deprecated_member_use
    return _fcm.getToken();
  }

  Stream<String> get tokenRenovado =>
      // ignore: deprecated_member_use
      _listo ? _fcm.onTokenRefresh : const Stream.empty();

  Future<void> borrarToken() async {
    // ignore: deprecated_member_use
    if (_listo) await _fcm.deleteToken();
  }

  /// Los datos (data) de la notificación que abrió la app estando cerrada.
  Future<Map<String, dynamic>?> datosMensajeInicial() async {
    if (!_listo) return null;
    final mensaje = await _fcm.getInitialMessage();
    return mensaje?.data;
  }

  /// Los datos de cada notificación tocada con la app en segundo plano.
  Stream<Map<String, dynamic>> get datosMensajesTocados => _listo
      ? FirebaseMessaging.onMessageOpenedApp.map((m) => m.data)
      : const Stream.empty();
}
