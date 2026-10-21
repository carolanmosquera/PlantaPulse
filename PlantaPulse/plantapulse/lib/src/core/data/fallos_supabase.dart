// lib/src/core/data/fallos_supabase.dart
// Convierte las excepciones de Supabase en los fallos del dominio.
import 'dart:async';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../errors/fallos.dart';

/// Mensajes por tipo de fallo, para que cada repositorio pueda dar uno
/// más específico ("No tienes permiso para ver las órdenes...").
FalloApp falloDesdeSupabase(
  Object e, {
  String permisos = 'No tienes permiso para realizar esta operación.',
  String sinConexion = 'Sin conexión. Revisa tu internet.',
  String duplicado = 'Ese registro ya existe.',
  String generico = 'Ocurrió un error inesperado. Intenta de nuevo.',
}) {
  if (e is FalloApp) return e;
  if (e is PostgrestException) {
    // 42501: RLS o un trigger proteger_* rechazó la escritura.
    // PGRST301/302: el token de sesión no es válido o venció.
    // 23505: violación de un índice único (nombre o serial repetido).
    // P0001/P0002: 'raise exception' de una función nuestra (p. ej.
    // eliminar_orden); su mensaje ya está en español y explica el motivo.
    return switch (e.code) {
      '42501' || 'PGRST301' || 'PGRST302' => FalloPermisos(permisos),
      '23505' => FalloApp(duplicado),
      'P0001' || 'P0002' => FalloApp(e.message),
      _ => FalloApp(generico),
    };
  }
  if (e is StorageException) {
    // 401/403: la política del bucket la rechazó (p. ej. la ruta no empieza
    // por la planta del usuario). 413 y mime: límites del bucket.
    final detalle = '${e.error ?? ''} ${e.message}'.toLowerCase();
    if (e.statusCode == '401' || e.statusCode == '403' ||
        detalle.contains('row-level security')) {
      return FalloPermisos(permisos);
    }
    if (e.statusCode == '413' || detalle.contains('size')) {
      return const FalloApp('La foto es demasiado grande (máximo 5 MB).');
    }
    if (detalle.contains('mime')) {
      return const FalloApp('Formato de imagen no admitido. Usa JPG, PNG o WEBP.');
    }
    return FalloApp(generico);
  }
  // http convierte los SocketException en ClientException (también en web)
  if (e is ClientException ||
      e is TimeoutException ||
      e is RealtimeSubscribeException ||
      e is AuthRetryableFetchException) {
    return FalloRed(sinConexion);
  }
  return FalloApp(generico);
}

/// Ejecuta una operación y traduce cualquier excepción a FalloApp.
/// [duplicado] es el mensaje para un 23505, que depende de qué se guarda.
Future<T> traducirSupabase<T>(
  Future<T> Function() operacion, {
  String? duplicado,
}) async {
  try {
    return await operacion();
  } catch (e) {
    throw duplicado == null
        ? falloDesdeSupabase(e)
        : falloDesdeSupabase(e, duplicado: duplicado);
  }
}

/// Lo mismo para un stream: cada error que emita llega como FalloApp.
extension TraducirErroresSupabase<T> on Stream<T> {
  Stream<T> traducirErrores(FalloApp Function(Object e) traducir) =>
      transform(StreamTransformer.fromHandlers(
        handleError: (e, st, sink) => sink.addError(traducir(e), st),
      ));
}
