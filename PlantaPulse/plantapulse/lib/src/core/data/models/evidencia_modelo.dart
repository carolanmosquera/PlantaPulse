// lib/src/core/data/models/evidencia_modelo.dart
import '../../domain/entities/evidencia.dart';
import '../json_helpers.dart';

/// Una foto dentro del arreglo jsonb 'evidencias'. Dentro del jsonb las
/// claves van en camelCase, igual que en UsuarioRef:
/// `{"ruta": "planta_norte/9f3c.../a3f9c1.jpg",
///   "subidaEn": "2026-10-19T22:14:03.000Z", "autorUid": "1e74..."}`
class EvidenciaModelo extends Evidencia {
  const EvidenciaModelo({
    required super.ruta,
    required super.subidaEn,
    required super.autorUid,
  });

  factory EvidenciaModelo.desdeEntidad(Evidencia e) => EvidenciaModelo(
        ruta: e.ruta,
        subidaEn: e.subidaEn,
        autorUid: e.autorUid,
      );

  factory EvidenciaModelo.fromJson(Map<String, dynamic> m) => EvidenciaModelo(
        ruta: texto(m['ruta']),
        subidaEn: fecha(m['subidaEn']),
        autorUid: texto(m['autorUid']),
      );

  /// subidaEn en UTC con aIso, como todas las fechas que se escriben.
  Map<String, dynamic> toJson() => {
        'ruta': ruta,
        'subidaEn': aIso(subidaEn),
        'autorUid': autorUid,
      };
}

/// Una entrada sin ruta no se puede pintar: se descarta al leer.
List<Evidencia> evidenciasDesdeJson(dynamic valor) => listaMapas(valor)
    .map(EvidenciaModelo.fromJson)
    .where((e) => e.ruta.isNotEmpty)
    .toList();

List<Map<String, dynamic>> evidenciasAJson(List<Evidencia> evidencias) =>
    evidencias.map((e) => EvidenciaModelo.desdeEntidad(e).toJson()).toList();
