// lib/src/features/novedades/data/repositories/alerta_critica_repositorio_impl.dart
import '../../../../core/data/models/alerta_modelo.dart';
import '../../../../core/domain/entities/alerta.dart';
import '../../../../core/domain/entities/alerta_critica.dart';
import '../../domain/repositories/alerta_critica_repositorio.dart';
import '../datasources/alerta_critica_fuente_supabase.dart';
import '../datasources/ubicacion_fuente_geolocator.dart';

class AlertaCriticaRepositorioImpl implements AlertaCriticaRepositorio {
  final AlertaCriticaFuenteSupabase _fuente;

  AlertaCriticaRepositorioImpl(this._fuente);

  @override
  Future<void> enviar(AlertaCritica a) => _fuente.insertar(AlertaCriticaModelo(
        id: a.id,
        plantaId: a.plantaId,
        zonaId: a.zonaId,
        zonaNombre: a.zonaNombre,
        ordenId: a.ordenId,
        tipo: a.tipo,
        descripcion: a.descripcion,
        creadoPor: a.creadoPor,
        ubicacionGps: a.ubicacionGps,
        evidencias: a.evidencias,
        estado: EstadoAlerta.abierta,
        createdAt: a.createdAt,
      ).toJson());

  /// Solo las abiertas, las más nuevas primero (ordenadas sobre DateTime).
  @override
  Stream<List<AlertaCritica>> abiertasDeLaPlanta(String plantaId) =>
      _fuente.deLaPlanta(plantaId).map((filas) => filas
          .map(AlertaCriticaModelo.fromJson)
          .where((a) => a.estado == EstadoAlerta.abierta)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
}

class UbicacionRepositorioImpl implements UbicacionRepositorio {
  final UbicacionFuenteGeolocator _fuente;

  UbicacionRepositorioImpl(this._fuente);

  @override
  Future<PuntoGps?> actual() async {
    final p = await _fuente.posicion();
    return p == null ? null : PuntoGps(p.latitud, p.longitud);
  }
}
