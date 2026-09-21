// lib/src/models/firestore_helpers.dart
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

/// Formatea una fecha como "08:00 AM"
String horaAmPm(DateTime f) {
  final h24 = f.hour;
  final sufijo = h24 < 12 ? 'AM' : 'PM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final min = f.minute.toString().padLeft(2, '0');
  return '${h12.toString().padLeft(2, '0')}:$min $sufijo';
}

/// Formatea como "Hoy, 16:00" / "24 May, 09:00"
String fechaCorta(DateTime f) {
  final ahora = DateTime.now();
  final hhmm =
      '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

  final esHoy = f.year == ahora.year && f.month == ahora.month && f.day == ahora.day;
  if (esHoy) return 'Hoy, $hhmm';

  const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
  return '${f.day} ${meses[f.month - 1]}, $hhmm';
}

/// Agrupa una fecha en 'HOY' | 'AYER' | 'ESTA SEMANA' | 'ANTERIORES'
String grupoRelativo(DateTime f) {
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(f.year, f.month, f.day);
  final diff = hoy.difference(dia).inDays;

  if (diff <= 0) return 'HOY';
  if (diff == 1) return 'AYER';
  if (diff <= 7) return 'ESTA SEMANA';
  return 'ANTERIORES';
}