// lib/src/core/data/datasources/ia_fuente_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../errors/fallos.dart';
import '../fallos_supabase.dart';

/// El ÚNICO archivo del proyecto que llama a `functions.invoke`. Habla con
/// la Edge Function 'ia' (el proxy hacia Gemini) y devuelve el JSON crudo;
/// convertirlo en entidades es trabajo del repositorio.
///
/// El cliente de Supabase adjunta solo el token de la sesión: la función
/// exige un usuario con sesión iniciada.
///
/// Sin reintentos: cada llamada gasta cuota, y si falla decide la persona.
class IaFuenteSupabase {
  final SupabaseClient? _cliente;

  IaFuenteSupabase({this._cliente});

  // Se resuelve al llamar, no al construir: crear la fuente no exige que
  // Supabase esté inicializado (las pruebas de pantalla la construyen
  // sin usarla).
  SupabaseClient get _db => _cliente ?? Supabase.instance.client;

  Future<Map<String, dynamic>> estructurarOrden(String nota) =>
      _invocar('estructurar_orden', {'nota': nota});

  Future<Map<String, dynamic>> redactarReporte({
    required String notas,
    required String equipo,
  }) =>
      _invocar('redactar_reporte', {'notas': notas, 'equipo': equipo});

  Future<Map<String, dynamic>> resumenTurno(Map<String, int> cifras) =>
      _invocar('resumen_turno', {'cifras': cifras});

  /// [datos] ya viene armado por el repositorio: {orden, reportes}.
  Future<Map<String, dynamic>> progresoOrden(Map<String, dynamic> datos) =>
      _invocar('progreso_orden', datos);

  Future<Map<String, dynamic>> _invocar(
    String tipo,
    Map<String, dynamic> datos,
  ) async {
    final FunctionResponse respuesta;
    try {
      respuesta = await _db.functions.invoke(
        'ia',
        body: {'tipo': tipo, 'datos': datos},
      );
    } catch (e) {
      // Un no-2xx llega como FunctionException con el {"error": ...} de la
      // función ya decodificado; el helper deja pasar ese mensaje.
      throw falloDesdeSupabase(
        e,
        permisos: 'Tu sesión venció. Vuelve a iniciar sesión para usar '
            'el asistente.',
        sinConexion: 'Sin conexión: el asistente no está disponible.',
        generico: 'El asistente no está disponible ahora.',
      );
    }
    final datosRespuesta = respuesta.data;
    if (datosRespuesta is Map) return Map<String, dynamic>.from(datosRespuesta);
    throw const FalloApp('El asistente devolvió una respuesta ilegible.');
  }
}
