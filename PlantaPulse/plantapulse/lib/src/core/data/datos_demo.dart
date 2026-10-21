// lib/src/core/data/datos_demo.dart
//
// Datos de prueba para las pantallas que todavía no tienen tabla.
// Solo queda lo que usa la pantalla de Alertas (avisos personales, sin
// tabla 'notificaciones' aún). Órdenes, equipos y reportes ya vienen de
// Supabase: sus datos de demo se borraron.
import '../domain/entities/alerta.dart';

/// Hoy a la hora indicada, para que "Hoy, 16:00" siga siendo verdad mañana.
DateTime _hoyA(int hora, [int minuto = 0]) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, hora, minuto);
}

DateTime _enDias(int dias, int hora, [int minuto = 0]) =>
    _hoyA(hora, minuto).add(Duration(days: dias));

// ─────────────────────────────────────────────────────────────
// ALERTAS (usuarios/{uid}/notificaciones)
// El grupo (HOY / AYER / ...) ya no se guarda: sale de createdAt.
// ─────────────────────────────────────────────────────────────

final alertasDemo = <Alerta>[
  Alerta(
    id: 'al-1',
    tipo: TipoAlerta.critica,
    titulo: 'FALLA CRÍTICA DETECTADA',
    descripcion: 'Sensor de temperatura en Turbina-04 ha superado el límite '
        'operativo (105°C).',
    codigo: 'OT-8842',
    createdAt: _hoyA(10, 45),
  ),
  Alerta(
    id: 'al-2',
    tipo: TipoAlerta.preventiva,
    titulo: 'MANTENIMIENTO PREVENTIVO',
    descripcion: 'La inspección mensual de la Cinta Transportadora B está '
        'programada.',
    createdAt: _hoyA(9, 15),
  ),
  Alerta(
    id: 'al-3',
    tipo: TipoAlerta.completada,
    titulo: 'ORDEN DE TRABAJO',
    descripcion: 'La reparación del Motor Sincrónico M-12 ha sido validada '
        'por el supervisor.',
    codigo: 'OT-8839',
    noLeida: false,
    createdAt: _hoyA(8, 30),
  ),
  Alerta(
    id: 'al-4',
    tipo: TipoAlerta.info,
    titulo: 'ACTUALIZACIÓN DE MANUAL',
    descripcion: 'Se ha actualizado el manual de seguridad para el manejo de '
        'químicos en zona C.',
    noLeida: false,
    createdAt: _enDias(-1, 16, 20),
  ),
  Alerta(
    id: 'al-5',
    tipo: TipoAlerta.critica,
    titulo: 'BAJA PRESIÓN DE ACEITE',
    descripcion: 'Alerta de sistema en Compresor Principal. Se requiere '
        'revisión de niveles.',
    codigo: 'OT-8835',
    noLeida: false,
    createdAt: _enDias(-1, 11, 10),
  ),
  Alerta(
    id: 'al-6',
    tipo: TipoAlerta.completada,
    titulo: 'REEMPLAZO DE FILTROS',
    descripcion: 'Sistemas de ventilación primaria operando al 100% tras '
        'cambio de componentes.',
    codigo: 'OT-8821',
    noLeida: false,
    createdAt: _enDias(-3, 15),
  ),
];
