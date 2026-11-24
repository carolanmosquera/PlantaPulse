import '../entities/preferencias_usuario.dart';

abstract class PreferenciasRepositorio {
  Future<PreferenciasUsuario> obtener(String uid);

  /// Devuelve las preferencias confirmadas por el servidor.
  Future<PreferenciasUsuario> cambiar(
    String uid,
    Preferencia campo,
    bool valor,
  );
}
