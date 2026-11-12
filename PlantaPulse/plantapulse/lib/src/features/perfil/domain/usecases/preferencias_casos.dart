import '../entities/preferencias_usuario.dart';
import '../repositories/preferencias_repositorio.dart';

class ObtenerPreferencias {
  final PreferenciasRepositorio _repositorio;
  const ObtenerPreferencias(this._repositorio);

  Future<PreferenciasUsuario> ejecutar(String uid) => _repositorio.obtener(uid);
}

class CambiarPreferencia {
  final PreferenciasRepositorio _repositorio;
  const CambiarPreferencia(this._repositorio);

  Future<PreferenciasUsuario> ejecutar(
    String uid,
    Preferencia campo,
    bool valor,
  ) => _repositorio.cambiar(uid, campo, valor);
}
