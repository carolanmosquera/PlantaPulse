
import '../../../../core/domain/entities/foto_elegida.dart';

abstract class FotoPerfilRepositorio {
  Future<String> subir({
    required String uid,
    required FotoElegida foto,
  });
}

class SubirFotoPerfil {
  final FotoPerfilRepositorio _fotos;

  const SubirFotoPerfil(this._fotos);

  Future<String> ejecutar({
    required String uid,
    required FotoElegida foto,
  }) {
    return _fotos.subir(
      uid: uid,
      foto: foto,
    );
  }
}
