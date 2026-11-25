import '../../../../core/data/models/alerta_modelo.dart';
import '../../../../core/domain/entities/alerta.dart';
import '../../domain/repositories/avisos_repositorio.dart';
import '../datasources/avisos_fuente_supabase.dart';

class AvisosRepositorioImpl implements AvisosRepositorio {
  final AvisosFuenteSupabase _fuente;

  AvisosRepositorioImpl(this._fuente);

  @override
  Stream<List<Alerta>> delUsuario(String usuarioId) =>
      _fuente.delUsuario(usuarioId).map((filas) => filas
          // Archivados por el servidor (p. ej. su alerta ya se solucionó):
          // ya no se muestran
          .where((f) => f['archivada'] != true)
          .map(AlertaModelo.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Future<void> marcarLeida({
    required String usuarioId,
    required String avisoId,
  }) =>
      _fuente.marcarLeida(usuarioId: usuarioId, avisoId: avisoId);
}
