// lib/src/core/data/models/novedad_modelo.dart
import '../../domain/entities/novedad.dart';
import '../json_helpers.dart';
import 'evidencia_modelo.dart';
import 'usuario_modelo.dart';

/// Fila de la tabla 'novedades'.
class NovedadModelo extends Novedad {
  const NovedadModelo({
    required super.id,
    required super.plantaId,
    super.zonaId,
    super.zonaNombre,
    required super.descripcion,
    super.categoria,
    required super.autor,
    super.evidencias,
    super.estado,
    super.ordenId,
    super.revisadaPor,
    super.revisadaEn,
    required super.createdAt,
  });

  factory NovedadModelo.fromJson(Map<String, dynamic> j) => NovedadModelo(
        id: texto(j['id']),
        plantaId: texto(j['planta_id']),
        zonaId: texto(j['zona_id']),
        zonaNombre: texto(j['zona_nombre']),
        descripcion: texto(j['descripcion']),
        categoria: CategoriaNovedadX.desdeDb(j['categoria']),
        autor: UsuarioRefModelo.fromJson(mapa(j['autor'])),
        evidencias: evidenciasDesdeJson(j['evidencias']),
        estado: EstadoNovedadX.desdeDb(j['estado']),
        ordenId: textoOpcional(j['orden_id']),
        revisadaPor: UsuarioRefModelo.fromJsonOpcional(j['revisada_por']),
        revisadaEn: fechaOpcional(j['revisada_en']),
        createdAt: fecha(j['created_at']),
      );

  /// Sin id ni created_at: los ponen Postgres y el trigger.
  Map<String, dynamic> toJson() => {
        'planta_id': plantaId,
        'zona_id': zonaId,
        'zona_nombre': zonaNombre,
        'descripcion': descripcion,
        'categoria': categoria.db,
        'autor': refAJson(autor),
        'evidencias': evidenciasAJson(evidencias),
        'estado': estado.db,
        'orden_id': ordenId,
        'revisada_por': refAJsonOpcional(revisadaPor),
        'revisada_en': aIsoOpcional(revisadaEn),
      };
}
