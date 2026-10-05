// lib/src/core/domain/entities/alerta_critica.dart
import 'alerta.dart';
import 'evidencia.dart';
import '../utils/formato_fechas.dart';
import 'usuario.dart';

/// Coordenadas GPS sin depender de ningún SDK de base de datos.
class PuntoGps {
  final double latitude;
  final double longitude;

  const PuntoGps(this.latitude, this.longitude);
}

/// Evento de seguridad reportado desde la pantalla de Emergencia.
/// Colección raíz 'alertas': debe verse aunque no venga de ninguna orden.
class AlertaCritica {
  final String id;
  final String plantaId;
  final String zonaId;
  final String zonaNombre;
  final String? ordenId;          // opcional: puede no venir de una orden
  final TipoEmergencia tipo;
  final String descripcion;
  final UsuarioRef creadoPor;
  final PuntoGps? ubicacionGps;
  final List<Evidencia> evidencias;
  final EstadoAlerta estado;
  final DateTime createdAt;

  const AlertaCritica({
    required this.id,
    required this.plantaId,
    this.zonaId = '',
    this.zonaNombre = '',
    this.ordenId,
    required this.tipo,
    required this.descripcion,
    required this.creadoPor,
    this.ubicacionGps,
    this.evidencias = const [],
    this.estado = EstadoAlerta.abierta,
    required this.createdAt,
  });

  String get hora => horaAmPm(createdAt);

  /// "Planta Norte • Sector A-04 (GPS: 19.43, -99.13)"
  String get ubicacionTexto {
    if (ubicacionGps == null) return zonaNombre;
    final lat = ubicacionGps!.latitude.toStringAsFixed(2);
    final lng = ubicacionGps!.longitude.toStringAsFixed(2);
    return '$zonaNombre (GPS: $lat, $lng)';
  }
}