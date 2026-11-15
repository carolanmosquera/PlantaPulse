import '../../../../core/domain/entities/alerta.dart';

abstract class AvisosRepositorio {
  Stream<List<Alerta>> delUsuario(String usuarioId);

  Future<void> marcarLeida({
    required String usuarioId,
    required String avisoId,
  });
}
