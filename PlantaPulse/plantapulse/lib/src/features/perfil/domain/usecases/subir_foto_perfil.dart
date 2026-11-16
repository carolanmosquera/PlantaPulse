
import '../../../../core/domain/entities/foto_elegida.dart';
import '../repositories/foto_perfil_repositorio.dart';

class SubirFotoPerfil {
  final dynamic _fotos;

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
