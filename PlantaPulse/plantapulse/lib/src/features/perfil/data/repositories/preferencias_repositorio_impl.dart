import '../../domain/entities/preferencias_usuario.dart';
import '../../domain/repositories/preferencias_repositorio.dart';
import '../datasources/preferencias_fuente_supabase.dart';
import '../models/preferencias_modelo.dart';

class PreferenciasRepositorioImpl implements PreferenciasRepositorio {
  final PreferenciasFuenteSupabase _fuente;
  const PreferenciasRepositorioImpl(this._fuente);

  @override
  Future<PreferenciasUsuario> obtener(String uid) async =>
      PreferenciasModelo.desdeJson(await _fuente.obtener(uid));

  @override
  Future<PreferenciasUsuario> cambiar(
    String uid,
    Preferencia campo,
    bool valor,
  ) async => PreferenciasModelo.desdeJson(
    await _fuente.cambiar(uid, PreferenciasModelo.clave(campo), valor),
  );
}
