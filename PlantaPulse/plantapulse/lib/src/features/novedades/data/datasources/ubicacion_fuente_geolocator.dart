// lib/src/features/novedades/data/datasources/ubicacion_fuente_geolocator.dart
import 'package:geolocator/geolocator.dart';

/// El único lugar que habla con el GPS del dispositivo.
class UbicacionFuenteGeolocator {
  /// Posición actual, o null si el GPS está apagado, el usuario negó el
  /// permiso o no se pudo obtener a tiempo.
  Future<({double latitud, double longitud})?> posicion() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }

      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitud: p.latitude, longitud: p.longitude);
    } catch (_) {
      return null; // sin GPS la alerta se envía igual
    }
  }
}
