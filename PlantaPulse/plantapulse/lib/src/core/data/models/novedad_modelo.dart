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
    super.motivoDescarte,
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
        motivoDescarte: textoOpcional(j['motivo_descarte']),
        createdAt: fecha(j['created_at']),
      );

  factory NovedadModelo.desdeEntidad(Novedad novedad) => NovedadModelo(
        id: novedad.id,
        plantaId: novedad.plantaId,
        zonaId: novedad.zonaId,
        zonaNombre: novedad.zonaNombre,
        descripcion: novedad.descripcion,
        categoria: novedad.categoria,
        autor: novedad.autor,
        evidencias: novedad.evidencias,
        createdAt: novedad.createdAt,
      );

  /// Datos de alta. El servidor fija la fecha y el estado inicial.
  Map<String, dynamic> toJson() => {
        'id': id,
        'planta_id': plantaId,
        'zona_id': zonaId,
        'zona_nombre': zonaNombre,
        'descripcion': descripcion,
        'categoria': categoria.db,
        'autor': refAJson(autor),
        'evidencias': evidenciasAJson(evidencias),
      };
}
