// lib/src/core/data/models/evidencia_modelo.dart
import '../../domain/entities/evidencia.dart';
import '../json_helpers.dart';

/// Una foto dentro del arreglo jsonb 'evidencias'. Dentro del jsonb las
/// claves van en camelCase, igual que en UsuarioRef.
class EvidenciaModelo extends Evidencia {
  const EvidenciaModelo({
    required super.posicion,
    required super.url,
    required super.thumbUrl,
    required super.publicId,
    super.ancho,
    super.alto,
    required super.tomadaEn,
  });

  factory EvidenciaModelo.desdeEntidad(Evidencia e) => EvidenciaModelo(
        posicion: e.posicion,
        url: e.url,
        thumbUrl: e.thumbUrl,
        publicId: e.publicId,
        ancho: e.ancho,
        alto: e.alto,
        tomadaEn: e.tomadaEn,
      );

  factory EvidenciaModelo.fromJson(Map<String, dynamic> m) => EvidenciaModelo(
        posicion: PosicionFotoX.desdeDb(m['posicion']),
        url: texto(m['url']),
        thumbUrl: texto(m['thumbUrl'], texto(m['url'])),
        publicId: texto(m['publicId']),
        ancho: entero(m['ancho']),
        alto: entero(m['alto']),
        tomadaEn: fecha(m['tomadaEn']),
      );

  Map<String, dynamic> toJson() => {
        'posicion': posicion.db,
        'url': url,
        'thumbUrl': thumbUrl,
        'publicId': publicId,
        'ancho': ancho,
        'alto': alto,
        'tomadaEn': aIso(tomadaEn),
      };
}

List<Evidencia> evidenciasDesdeJson(dynamic valor) =>
    listaMapas(valor).map(EvidenciaModelo.fromJson).toList();

List<Map<String, dynamic>> evidenciasAJson(List<Evidencia> evidencias) =>
    evidencias.map((e) => EvidenciaModelo.desdeEntidad(e).toJson()).toList();
