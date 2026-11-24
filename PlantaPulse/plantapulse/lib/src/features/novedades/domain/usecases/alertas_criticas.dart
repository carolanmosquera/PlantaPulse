// lib/src/features/novedades/domain/usecases/alertas_criticas.dart
import '../../../../core/domain/entities/alerta.dart';
import '../../../../core/domain/entities/alerta_critica.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/errors/fallos.dart';
import '../repositories/alerta_critica_repositorio.dart';

/// Arma y registra la alerta crítica del usuario conectado.
class EnviarAlertaCritica {
  /// Mismo límite que muestra la pantalla ("0/200").
  static const maxDescripcion = 200;
  static const minDescripcion = 10;

  final AlertaCriticaRepositorio _alertas;

  const EnviarAlertaCritica(this._alertas);

  Future<void> ejecutar({
    required Usuario usuario,
    required TipoEmergencia tipo,
    required String descripcion,
    PuntoGps? ubicacion,
  }) {
    final texto = descripcion.trim();
    if (texto.length < minDescripcion || texto.length > maxDescripcion) {
      return Future.error(const FalloApp(
          'Describe el incidente en $minDescripcion a $maxDescripcion '
          'caracteres.'));
    }
    if (usuario.plantaId.isEmpty) {
      return Future.error(
          const FalloApp('Tu cuenta aún no tiene una planta asignada.'));
    }
    return _alertas.enviar(AlertaCritica(
      id: '', // lo genera la base de datos
      plantaId: usuario.plantaId,
      zonaId: usuario.zonasAsignadas.length == 1
          ? usuario.zonasAsignadas.first
          : '',
      tipo: tipo,
      descripcion: texto,
      creadoPor: usuario.ref,
      ubicacionGps: ubicacion,
      createdAt: DateTime.now(), // el servidor lo reemplaza con su hora
    ));
  }
}

/// Alertas abiertas de la planta, en tiempo real.
class ObservarAlertasCriticas {
  final AlertaCriticaRepositorio _alertas;

  const ObservarAlertasCriticas(this._alertas);

  Stream<List<AlertaCritica>> ejecutar(String plantaId) =>
      _alertas.abiertasDeLaPlanta(plantaId);
}

/// Pide la ubicación actual (puede tardar unos segundos).
class ObtenerUbicacion {
  final UbicacionRepositorio _ubicacion;

  const ObtenerUbicacion(this._ubicacion);

  Future<PuntoGps?> ejecutar() => _ubicacion.actual();
}
