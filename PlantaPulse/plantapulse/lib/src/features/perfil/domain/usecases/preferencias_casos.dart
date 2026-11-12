import '../entities/preferencias_usuario.dart';
import '../repositories/preferencias_repositorio.dart';

class ObtenerPreferencias {
  final PreferenciasRepositorio _repositorio;
  const ObtenerPreferencias(this._repositorio);

  Future<PreferenciasUsuario> ejecutar(String uid) => _repositorio.obtener(uid);
}

class CambiarPreferencia {
  final PreferenciasRepositorio _repositorio;
  final Future<void> Function(String uid, bool valor)? alCambiarPush;
  const CambiarPreferencia(this._repositorio, {this.alCambiarPush});

  Future<PreferenciasUsuario> ejecutar(
    String uid,
    Preferencia campo,
    bool valor,
  ) async {
    final guardadas = await _repositorio.cambiar(uid, campo, valor);
    if (campo == Preferencia.notificacionesPush) {
      await alCambiarPush?.call(uid, guardadas.notificacionesPush);
    }
    return guardadas;
  }
}
