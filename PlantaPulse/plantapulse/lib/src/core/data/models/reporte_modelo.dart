// lib/src/core/data/models/reporte_modelo.dart
import '../../domain/entities/reporte.dart';
import '../json_helpers.dart';
import 'evidencia_modelo.dart';
import 'usuario_modelo.dart';

/// Fila de la tabla 'reportes' (antes la subcolección ordenes/{id}/reportes).
class ReporteModelo extends Reporte {
  const ReporteModelo({
    required super.id,
    required super.ordenId,
    required super.autor,
    required super.detalles,
    super.estadoTrabajo,
    super.evidencias,
    super.esAlertaCritica,
    super.generadoPorIA,
    required super.createdAt,
  });

  factory ReporteModelo.fromJson(Map<String, dynamic> j) => ReporteModelo(
        id: texto(j['id']),
        ordenId: texto(j['orden_id']),
        autor: UsuarioRefModelo.fromJson(mapa(j['autor'])),
        detalles: texto(j['detalles']),
        estadoTrabajo: EstadoTrabajoX.desdeDb(j['estado_trabajo']),
        evidencias: evidenciasDesdeJson(j['evidencias']),
        esAlertaCritica: booleano(j['es_alerta_critica']),
        generadoPorIA: booleano(j['generado_por_ia']),
        createdAt: fecha(j['created_at']),
      );

  /// Sin id ni created_at: los ponen Postgres y el trigger.
  Map<String, dynamic> toJson() => {
        'orden_id': ordenId,
        'autor': refAJson(autor),
        'detalles': detalles,
        'estado_trabajo': estadoTrabajo.db,
        'evidencias': evidenciasAJson(evidencias),
        'es_alerta_critica': esAlertaCritica,
        'generado_por_ia': generadoPorIA,
      };
}
