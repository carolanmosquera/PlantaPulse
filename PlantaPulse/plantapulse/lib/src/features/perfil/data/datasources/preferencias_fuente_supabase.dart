import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/fallos_supabase.dart';
import '../../../../core/errors/fallos.dart';

/// Auth permite editar únicamente la cuenta de la sesión, sin una API de admin.
/// Esta información nunca se utiliza para decidir el rol ni las políticas RLS.
class PreferenciasFuenteSupabase {
  static const claveMetadatos = 'plantapulse_preferencias';
  static const _espera = Duration(seconds: 15);
  final GoTrueClient _auth;

  PreferenciasFuenteSupabase({GoTrueClient? auth})
    : _auth = auth ?? Supabase.instance.client.auth;

  void _comprobarCuenta(String uid) {
    if (uid.isEmpty || _auth.currentUser?.id != uid) {
      throw const FalloAutenticacion(
        'Tu sesión cambió. Vuelve a iniciar sesión.',
      );
    }
  }

  Map<String, dynamic> _preferencias(User user) {
    final datos = user.userMetadata?[claveMetadatos];
    return datos is Map ? Map<String, dynamic>.from(datos) : {};
  }

  Future<User> _leerCuenta(String uid) async {
    _comprobarCuenta(uid);
    final respuesta = await _auth.getUser().timeout(_espera);
    _comprobarCuenta(uid);
    final usuario = respuesta.user;
    if (usuario == null || usuario.id != uid) {
      throw const FalloAutenticacion('No se pudo comprobar tu cuenta.');
    }
    return usuario;
  }

  Future<Map<String, dynamic>> obtener(String uid) =>
      _traducir(() async => _preferencias(await _leerCuenta(uid)));

  Future<Map<String, dynamic>> cambiar(
    String uid,
    String campo,
    bool valor,
  ) => _traducir(() async {
    // Se relee para conservar otras opciones guardadas desde otro dispositivo.
    final usuario = await _leerCuenta(uid);
    final cambios = {..._preferencias(usuario), campo: valor};
    _comprobarCuenta(uid);
    // Auth combina las claves de data con los metadatos existentes. Enviamos
    // únicamente nuestro espacio: nombre y otros metadatos no se sobrescriben.
    final respuesta = await _auth
        .updateUser(UserAttributes(data: {claveMetadatos: cambios}))
        .timeout(_espera);
    _comprobarCuenta(uid);
    final guardado = respuesta.user;
    if (guardado == null ||
        guardado.id != uid ||
        _preferencias(guardado)[campo] != valor) {
      throw const FalloApp(
        'No se pudo confirmar el cambio. Vuelve a cargar los ajustes.',
      );
    }
    return _preferencias(guardado);
  });

  Future<T> _traducir<T>(Future<T> Function() operacion) async {
    try {
      return await operacion();
    } on AuthRetryableFetchException {
      throw const FalloRed();
    } on AuthException {
      throw const FalloAutenticacion(
        'No se pudieron consultar o guardar tus preferencias. Revisa tu sesión e intenta de nuevo.',
      );
    } catch (e) {
      throw falloDesdeSupabase(
        e,
        generico:
            'No se pudieron guardar o cargar tus preferencias. Intenta de nuevo.',
      );
    }
  }
}
