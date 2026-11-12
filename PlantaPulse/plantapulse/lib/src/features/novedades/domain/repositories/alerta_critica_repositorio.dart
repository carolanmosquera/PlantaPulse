// lib/src/features/novedades/domain/repositories/alerta_critica_repositorio.dart
import '../../../../core/domain/entities/alerta_critica.dart';

/// Alertas de emergencia de la planta (KAN-90).
abstract class AlertaCriticaRepositorio {
  /// Registra la alerta. Al quedar guardada, todos los supervisores de la
  /// planta la reciben en tiempo real por [abiertasDeLaPlanta].
  Future<void> enviar(AlertaCritica alerta);

  /// Alertas abiertas de una planta en tiempo real, las más nuevas primero.
  Stream<List<AlertaCritica>> abiertasDeLaPlanta(String plantaId);
}

/// Ubicación del dispositivo. Devuelve null si no hay permiso, el GPS está
/// apagado o la plataforma no lo da: enviar la alerta nunca depende de él.
abstract class UbicacionRepositorio {
  Future<PuntoGps?> actual();
}
