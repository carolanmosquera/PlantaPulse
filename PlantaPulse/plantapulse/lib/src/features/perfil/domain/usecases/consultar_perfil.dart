import '../../../../core/domain/entities/planta.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/repositories/planta_repositorio.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';
import '../../../../core/errors/fallos.dart';

typedef DatosPerfil = ({Usuario usuario, Planta? planta});

class ConsultarPerfil {
  final UsuarioRepositorio _usuarios;
  final PlantaRepositorio _plantas;
  const ConsultarPerfil(this._usuarios, this._plantas);

  Future<DatosPerfil> ejecutar(String uid) async {
    final usuario = await _usuarios.obtener(uid);
    if (usuario == null) {
      throw const FalloApp('No se pudo encontrar tu perfil. Intenta de nuevo.');
    }
    final planta = usuario.plantaId.isEmpty
        ? null
        : await _plantas.obtener(usuario.plantaId);
    return (usuario: usuario, planta: planta);
  }
}
