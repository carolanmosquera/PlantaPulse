import '../../domain/entities/preferencias_usuario.dart';
import '../../domain/repositories/preferencias_repositorio.dart';
import '../../../../core/domain/repositories/usuario_repositorio.dart';
import '../../../../core/domain/entities/preferencias_avisos.dart';
import '../../../../core/errors/fallos.dart';
import '../datasources/preferencias_fuente_supabase.dart';
import '../models/preferencias_modelo.dart';

class PreferenciasRepositorioImpl implements PreferenciasRepositorio {
  final PreferenciasFuenteSupabase _fuente;
  final UsuarioRepositorio _usuarios;
  const PreferenciasRepositorioImpl(this._fuente, this._usuarios);

  Future<PreferenciasAvisos> _avisos(String uid) async {
    final usuario = await _usuarios.obtener(uid);
    if (usuario == null) {
      throw const FalloApp('No se encontró el perfil de la cuenta.');
    }
    return usuario.preferenciasAvisos;
  }

  PreferenciasUsuario _combinar(
    PreferenciasAvisos avisos,
    Map<String, dynamic> metadata,
  ) {
    final auth = PreferenciasModelo.desdeJson(metadata);
    return PreferenciasUsuario(
      notificacionesPush: avisos.push,
      alertasMantenimiento: avisos.mantenimiento,
      soloCriticas: avisos.soloCriticas,
      modoOscuro: auth.modoOscuro,
      modoOffline: auth.modoOffline,
    );
  }

  @override
  Future<PreferenciasUsuario> obtener(String uid) async {
    final metadata = await _fuente.obtener(uid);
    return _combinar(await _avisos(uid), metadata);
  }

  @override
  Future<PreferenciasUsuario> cambiar(
    String uid,
    Preferencia campo,
    bool valor,
  ) async {
    if (campo == Preferencia.modoOscuro || campo == Preferencia.modoOffline) {
      final metadata = await _fuente.cambiar(
        uid,
        PreferenciasModelo.clave(campo),
        valor,
      );
      return _combinar(await _avisos(uid), metadata);
    }
    final metadata = await _fuente.obtener(uid);
    final actual = await _avisos(uid);
    final nuevos = switch (campo) {
      Preferencia.notificacionesPush => actual.copyWith(push: valor),
      Preferencia.alertasMantenimiento => actual.copyWith(mantenimiento: valor),
      Preferencia.soloCriticas => actual.copyWith(soloCriticas: valor),
      _ => actual,
    };
    await _usuarios.actualizar(uid, {'preferenciasAvisos': nuevos.toJson()});
    final confirmados = await _avisos(uid);
    final confirmado = switch (campo) {
      Preferencia.notificacionesPush => confirmados.push,
      Preferencia.alertasMantenimiento => confirmados.mantenimiento,
      Preferencia.soloCriticas => confirmados.soloCriticas,
      _ => valor,
    };
    if (confirmado != valor) {
      throw const FalloApp(
        'No se pudo confirmar el cambio. Vuelve a cargar los ajustes.',
      );
    }
    return _combinar(confirmados, metadata);
  }
}
