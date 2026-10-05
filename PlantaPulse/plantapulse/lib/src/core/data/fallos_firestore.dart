// lib/src/core/data/fallos_firestore.dart
// Convierte las excepciones de Firestore en los fallos del dominio.
// TODO fase B: reemplazar por la traducción de PostgrestException.
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../errors/fallos.dart';

/// Mensajes por código, para que cada repositorio pueda dar uno más
/// específico ("No tienes permiso para ver las órdenes...").
FalloApp falloDesdeFirestore(
  Object e, {
  String permisos = 'No tienes permiso para realizar esta operación.',
  String sinConexion = 'Sin conexión. Revisa tu internet.',
  String sinIndice = 'Falta un índice en la base de datos para esta consulta.',
  String generico = 'Ocurrió un error inesperado. Intenta de nuevo.',
}) {
  if (e is FalloApp) return e;
  if (e is FirebaseException) {
    return switch (e.code) {
      'permission-denied'   => FalloPermisos(permisos),
      'unavailable'         => FalloRed(sinConexion),
      'failed-precondition' => FalloApp(sinIndice),
      _                     => FalloApp(generico),
    };
  }
  return FalloApp(generico);
}

/// Ejecuta una operación y traduce cualquier excepción a FalloApp.
Future<T> traducirFirestore<T>(Future<T> Function() operacion) async {
  try {
    return await operacion();
  } catch (e) {
    throw falloDesdeFirestore(e);
  }
}

/// Lo mismo para un stream: cada error que emita llega como FalloApp.
extension TraducirErroresFirestore<T> on Stream<T> {
  Stream<T> traducirErrores(FalloApp Function(Object e) traducir) =>
      transform(StreamTransformer.fromHandlers(
        handleError: (e, st, sink) => sink.addError(traducir(e), st),
      ));
}
