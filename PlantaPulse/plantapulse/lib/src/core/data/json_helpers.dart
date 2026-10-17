// lib/src/core/data/firestore_helpers.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilidades para leer campos de Firestore sin que la app se caiga
/// cuando un documento viene incompleto o con un tipo inesperado.
///
/// Regla: NUNCA hagas json['campo'] as String directamente.
/// Si el campo falta, revienta. Con estos helpers devuelve un valor por defecto.

DateTime? fechaOpcional(dynamic valor) {
  if (valor == null) return null;
  if (valor is Timestamp) return valor.toDate();
  if (valor is DateTime) return valor;
  if (valor is String) return DateTime.tryParse(valor);
  return null;
}

DateTime fecha(dynamic valor) => fechaOpcional(valor) ?? DateTime.now();

String texto(dynamic valor, [String porDefecto = '']) =>
    valor is String ? valor : porDefecto;

String? textoOpcional(dynamic valor) =>
    (valor is String && valor.isNotEmpty) ? valor : null;

int entero(dynamic valor, [int porDefecto = 0]) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return porDefecto;
}

bool booleano(dynamic valor, [bool porDefecto = false]) =>
    valor is bool ? valor : porDefecto;

List<String> listaTexto(dynamic valor) =>
    valor is List ? valor.map((e) => e.toString()).toList() : const <String>[];

Map<String, dynamic> mapa(dynamic valor) =>
    valor is Map ? Map<String, dynamic>.from(valor) : <String, dynamic>{};

List<Map<String, dynamic>> listaMapas(dynamic valor) => valor is List
    ? valor.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const <Map<String, dynamic>>[];
