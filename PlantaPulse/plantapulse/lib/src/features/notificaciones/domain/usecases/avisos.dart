import '../../../../core/domain/entities/alerta.dart';
import '../repositories/avisos_repositorio.dart';

class ObservarAvisos {
  final AvisosRepositorio _avisos;

  const ObservarAvisos(this._avisos);

  Stream<List<Alerta>> ejecutar(String usuarioId) =>
      _avisos.delUsuario(usuarioId);
}

class MarcarAvisoLeido {
  final AvisosRepositorio _avisos;

  const MarcarAvisoLeido(this._avisos);

  Future<void> ejecutar({
    required String usuarioId,
    required String avisoId,
  }) =>
      _avisos.marcarLeida(usuarioId: usuarioId, avisoId: avisoId);
}
