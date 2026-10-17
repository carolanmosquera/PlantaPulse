// lib/src/core/data/json_helpers.dart

// Utilidades para leer filas JSON de Supabase sin que la app se caiga
// cuando una columna viene vacía o con un tipo inesperado.
//
// Regla: NUNCA hagas json['campo'] as String directamente.
// Si el campo falta, revienta. Con estos helpers devuelve un valor por defecto.

/// Postgres devuelve las fechas como texto ISO en UTC
/// ("2026-10-05T17:30:00+00:00"). Se pasan a hora local: así se
/// comportan igual que las fechas de antes y la UI
/// muestra la hora del teléfono, no la de Greenwich.
DateTime? fechaOpcional(dynamic valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor.toLocal();
  if (valor is String) return DateTime.tryParse(valor)?.toLocal();
  return null;
}

DateTime fecha(dynamic valor) => fechaOpcional(valor) ?? DateTime.now();

/// Para escribir: SIEMPRE en UTC con zona explícita. Un DateTime local
/// sin zona ("2026-10-05T23:59:00") Postgres lo leería como UTC y la
/// fecha límite quedaría corrida 5 horas.
String aIso(DateTime f) => f.toUtc().toIso8601String();

String? aIsoOpcional(DateTime? f) => f == null ? null : aIso(f);

String texto(dynamic valor, [String porDefecto = '']) =>
    valor is String ? valor : porDefecto;

String? textoOpcional(dynamic valor) =>
    (valor is String && valor.isNotEmpty) ? valor : null;

int entero(dynamic valor, [int porDefecto = 0]) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return porDefecto;
}

double decimal(dynamic valor, [double porDefecto = 0]) =>
    valor is num ? valor.toDouble() : porDefecto;

bool booleano(dynamic valor, [bool porDefecto = false]) =>
    valor is bool ? valor : porDefecto;

List<String> listaTexto(dynamic valor) =>
    valor is List ? valor.map((e) => e.toString()).toList() : const <String>[];

Map<String, dynamic> mapa(dynamic valor) =>
    valor is Map ? Map<String, dynamic>.from(valor) : <String, dynamic>{};

List<Map<String, dynamic>> listaMapas(dynamic valor) => valor is List
    ? valor.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const <Map<String, dynamic>>[];

/// "asignadoAUid" → "asignado_a_uid". Para traducir los nombres de las
/// propiedades de la entidad a columnas cuando un contrato recibe un
/// mapa de cambios.
String aColumna(String propiedad) => propiedad.replaceAllMapped(
    RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
