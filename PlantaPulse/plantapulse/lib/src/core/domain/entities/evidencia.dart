// lib/src/core/domain/entities/evidencia.dart

/// Las cuatro posiciones fijas de la evidencia fotográfica.
/// Tener posiciones fijas en vez de una lista libre tiene tres ventajas:
///   1. El documento nunca crece: máximo 4 mapas pequeños.
///   2. El supervisor que valida sabe qué está viendo en cada foto.
///   3. La UI es una cuadrícula 2x2 con huecos etiquetados, no un "+" infinito.
enum PosicionFoto { frontal, posterior, lateralIzq, lateralDer }

extension PosicionFotoX on PosicionFoto {
  String get etiqueta => switch (this) {
        PosicionFoto.frontal    => 'Frontal',
        PosicionFoto.posterior  => 'Posterior',
        PosicionFoto.lateralIzq => 'Lateral izq.',
        PosicionFoto.lateralDer => 'Lateral der.',
      };

  String get db => switch (this) {
        PosicionFoto.frontal    => 'frontal',
        PosicionFoto.posterior  => 'posterior',
        PosicionFoto.lateralIzq => 'lateral_izq',
        PosicionFoto.lateralDer => 'lateral_der',
      };

  static PosicionFoto desdeDb(String? v) => switch (v) {
        'posterior'   => PosicionFoto.posterior,
        'lateral_izq' => PosicionFoto.lateralIzq,
        'lateral_der' => PosicionFoto.lateralDer,
        _             => PosicionFoto.frontal,
      };
}

/// Una foto de evidencia. El archivo vive en Cloudinary;
/// aquí solo guardamos las URLs y los datos para poder borrarla.
class Evidencia {
  final PosicionFoto posicion;
  final String url;        // imagen completa
  final String thumbUrl;   // miniatura para el feed
  final String publicId;   // identificador en Cloudinary, necesario para borrar
  final int ancho;
  final int alto;
  final DateTime tomadaEn;

  const Evidencia({
    required this.posicion,
    required this.url,
    required this.thumbUrl,
    required this.publicId,
    this.ancho = 0,
    this.alto = 0,
    required this.tomadaEn,
  });

}

/// Tope de fotos por reporte. Coincide con las cuatro posiciones.
const int maxFotosPorReporte = 4;

/// Devuelve qué posiciones quedan libres, para pintar los huecos de la cuadrícula.
List<PosicionFoto> posicionesLibres(List<Evidencia> actuales) {
  final usadas = actuales.map((e) => e.posicion).toSet();
  return PosicionFoto.values.where((p) => !usadas.contains(p)).toList();
}