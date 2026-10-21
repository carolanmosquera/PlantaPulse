// lib/src/core/domain/utils/formato_fechas.dart
// Formatos de fecha para mostrar. Dart puro: lo usan las entidades
// (getters como 'hora') y las pantallas.

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

/// "Hace un momento", "Hace 5 min", "Hace 2 h", "Ayer, 16:00", "24 May, 09:00"
String haceCuanto(DateTime f) {
  final diferencia = DateTime.now().difference(f);
  if (diferencia.inMinutes < 1) return 'Hace un momento';
  if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
  if (diferencia.inHours < 12) return 'Hace ${diferencia.inHours} h';
  if (grupoRelativo(f) == 'AYER') {
    final hhmm = '${f.hour.toString().padLeft(2, '0')}:'
        '${f.minute.toString().padLeft(2, '0')}';
    return 'Ayer, $hhmm';
  }
  return fechaCorta(f);
}
