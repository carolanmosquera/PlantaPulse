// lib/src/core/data/datasources/cola_reportes_fuente_local.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../errors/fallos.dart';

/// El único lugar que guarda en el teléfono los reportes sin enviar
/// (KAN-98). Una lista JSON por usuario: si en el teléfono entra otra
/// cuenta, no ve ni envía los reportes de la anterior.
/// Devuelve filas crudas; los errores salen como FalloApp.
class ColaReportesFuenteLocal {
  static String _clave(String uid) => 'cola_reportes_$uid';

  Future<List<Map<String, dynamic>>> leer(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_clave(uid));
      if (texto == null || texto.isEmpty) return [];
      return [
        for (final item in jsonDecode(texto) as List)
          Map<String, dynamic>.from(item as Map),
      ];
    } catch (_) {
      throw const FalloApp(
          'No se pudieron leer los reportes guardados en el teléfono.');
    }
  }

  Future<void> escribir(String uid, List<Map<String, dynamic>> filas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (filas.isEmpty) {
        await prefs.remove(_clave(uid));
      } else {
        await prefs.setString(_clave(uid), jsonEncode(filas));
      }
    } catch (_) {
      throw const FalloApp(
          'No se pudo guardar el reporte en el teléfono.');
    }
  }
}
