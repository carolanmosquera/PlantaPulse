// lib/src/core/data/models/alerta_modelo.dart
import '../../domain/entities/alerta.dart';
import '../../domain/entities/alerta_critica.dart';
import '../json_helpers.dart';
import 'evidencia_modelo.dart';
import 'usuario_modelo.dart';

/// Aviso personal del usuario.
/// OJO: el esquema actual de Supabase aún NO tiene tabla para estos
/// avisos; el modelo queda listo para cuando se cree 'notificaciones'.
class AlertaModelo extends Alerta {
  const AlertaModelo({
    required super.id,
    required super.tipo,
    required super.titulo,
    required super.descripcion,
    super.codigo,
    super.ordenId,
    super.noLeida,
    required super.createdAt,
  });

  factory AlertaModelo.fromJson(Map<String, dynamic> j) => AlertaModelo(
        id: texto(j['id']),
        tipo: TipoAlertaX.desdeDb(j['tipo']),
        titulo: texto(j['titulo']),
        descripcion: texto(j['descripcion']),
        codigo: textoOpcional(j['codigo']),
        ordenId: textoOpcional(j['orden_id']),
        noLeida: !booleano(j['leida']),     // en la base se guarda 'leida'
        createdAt: fecha(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'tipo': tipo.db,
        'titulo': titulo,
        'descripcion': descripcion,
        'codigo': codigo,
        'orden_id': ordenId,
        'leida': !noLeida,
      };
}

/// PuntoGps viaja en la columna jsonb ubicacion_gps:
/// {"latitude": 3.58, "longitude": -76.49}.
class PuntoGpsModelo extends PuntoGps {
  const PuntoGpsModelo(super.latitude, super.longitude);

  static PuntoGps? fromJsonOpcional(dynamic m) {
    if (m is! Map) return null;
    final lat = m['latitude'], lng = m['longitude'];
    if (lat is! num || lng is! num) return null;
    return PuntoGpsModelo(lat.toDouble(), lng.toDouble());
  }

  static Map<String, dynamic>? toJsonOpcional(PuntoGps? p) =>
      p == null ? null : {'latitude': p.latitude, 'longitude': p.longitude};
}

/// Fila de la tabla 'alertas' (emergencias).
class AlertaCriticaModelo extends AlertaCritica {
  const AlertaCriticaModelo({
    required super.id,
    required super.plantaId,
    super.zonaId,
    super.zonaNombre,
    super.ordenId,
    required super.tipo,
    required super.descripcion,
    required super.creadoPor,
    super.ubicacionGps,
    super.evidencias,
    super.estado,
    required super.createdAt,
  });

  factory AlertaCriticaModelo.fromJson(Map<String, dynamic> j) =>
      AlertaCriticaModelo(
        id: texto(j['id']),
        plantaId: texto(j['planta_id']),
        zonaId: texto(j['zona_id']),
        zonaNombre: texto(j['zona_nombre']),
        ordenId: textoOpcional(j['orden_id']),
        tipo: TipoEmergenciaX.desdeDb(j['tipo']),
        descripcion: texto(j['descripcion']),
        creadoPor: UsuarioRefModelo.fromJson(mapa(j['creado_por'])),
        ubicacionGps: PuntoGpsModelo.fromJsonOpcional(j['ubicacion_gps']),
        evidencias: evidenciasDesdeJson(j['evidencias']),
        estado: EstadoAlertaX.desdeDb(j['estado']),
        createdAt: fecha(j['created_at']),
      );

  /// Sin id ni created_at: los ponen Postgres y el trigger.
  Map<String, dynamic> toJson() => {
        'planta_id': plantaId,
        'zona_id': zonaId,
        'zona_nombre': zonaNombre,
        'orden_id': ordenId,
        'tipo': tipo.db,
        'descripcion': descripcion,
        'creado_por': refAJson(creadoPor),
        'ubicacion_gps': PuntoGpsModelo.toJsonOpcional(ubicacionGps),
        'evidencias': evidenciasAJson(evidencias),
        'estado': estado.db,
      };
}
