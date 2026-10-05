// lib/src/core/data/models/evidencia_mapa.dart
// TODO fase B: mover a data/models como EvidenciaModelo con fromJson/toJson.
import '../../domain/entities/evidencia.dart';
import '../firestore_helpers.dart';

Evidencia evidenciaDesdeMapa(Map<String, dynamic> m) => Evidencia(
      posicion: PosicionFotoX.desdeDb(m['posicion']),
      url: texto(m['url']),
      thumbUrl: texto(m['thumbUrl'], texto(m['url'])),
      publicId: texto(m['publicId']),
      ancho: entero(m['ancho']),
      alto: entero(m['alto']),
      tomadaEn: fecha(m['tomadaEn']),
    );

extension EvidenciaMapa on Evidencia {
  /// Dentro de un array de Firestore se guardan mapas planos,
  /// NO Timestamp anidado en objetos complejos: usamos texto ISO.
  Map<String, dynamic> aMapa() => {
        'posicion': posicion.db,
        'url': url,
        'thumbUrl': thumbUrl,
        'publicId': publicId,
        'ancho': ancho,
        'alto': alto,
        'tomadaEn': tomadaEn.toIso8601String(),
      };
}
