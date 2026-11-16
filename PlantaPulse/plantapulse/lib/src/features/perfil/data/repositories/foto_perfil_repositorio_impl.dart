
import '../../../../core/domain/entities/foto_elegida.dart';

import '../../domain/repositories/foto_perfil_repositorio.dart';
import '../datasources/foto_perfil_fuente_supabase.dart';

class FotoPerfilRepositorioImpl {
  final FotoPerfilFuenteSupabase _fuente;

  const FotoPerfilRepositorioImpl(this._fuente);

  Future<String> subir({
    required String uid,
    required FotoElegida foto,
  }) {
    return _fuente.subir(
      uid: uid,
      foto: foto,
    );
  }
}
