// lib/src/core/data/datos_demo.dart
//
// Datos de prueba con la estructura real de los modelos, para que las
// pantallas funcionen mientras la base de datos no está conectada.
// Cuando lo conectes, cada lista de aquí se reemplaza por un stream.
// TODO fase B: borrar este archivo.
import '../domain/entities/alerta.dart';
import '../domain/entities/equipo.dart';
import '../domain/entities/evidencia.dart';
import '../domain/entities/orden.dart';
import '../domain/entities/reporte.dart';
import '../domain/entities/usuario.dart';

const plantaDemoId = 'planta-norte';

const usuarioActualDemo = UsuarioRef(uid: 'demo-tecnico-1', nombre: 'Carlos Mendoza');
const supervisorDemo = UsuarioRef(uid: 'demo-supervisor-1', nombre: 'Laura Vega');

/// Hoy a la hora indicada, para que "Hoy, 16:00" siga siendo verdad mañana.
DateTime _hoyA(int hora, [int minuto = 0]) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, hora, minuto);
}

DateTime _enDias(int dias, int hora, [int minuto = 0]) =>
    _hoyA(hora, minuto).add(Duration(days: dias));

Orden _orden({
  required String id,
  required String codigo,
  required String titulo,
  required String zona,
  required EstadoOrden estado,
  required Prioridad prioridad,
  required DateTime limite,
  String descripcion = '',
  String categoria = 'Mecánico',
  String? equipoId,
  String? equipoNombre,
  int totalReportes = 0,
}) =>
    Orden(
      id: id,
      codigo: codigo,
      plantaId: plantaDemoId,
      titulo: titulo,
      descripcion: descripcion,
      categoria: categoria,
      zonaNombre: zona,
      equipoId: equipoId,
      equipoNombre: equipoNombre,
      creadoPor: supervisorDemo,
      asignadoA: usuarioActualDemo,
      asignadoAUid: usuarioActualDemo.uid,
      estado: estado,
      prioridad: prioridad,
      createdAt: _hoyA(8),
      fechaLimite: limite,
      ultimaActividad: _hoyA(8),
      totalReportes: totalReportes,
    );

// ─────────────────────────────────────────────────────────────
// EQUIPOS
// ─────────────────────────────────────────────────────────────

const equiposDemo = <Equipo>[
  Equipo(
    id: 'eq-ga75',
    plantaId: plantaDemoId,
    zonaNombre: 'Planta A - Sección Compresores',
    nombre: 'COMPRESOR GA75',
    serial: 'AC-88291-K',
    modelo: '2022',
    tipo: 'mecánico',
  ),
];

Equipo? equipoDemoPorId(String? id) {
  for (final e in equiposDemo) {
    if (e.id == id) return e;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────
// ÓRDENES (Feed)
// ─────────────────────────────────────────────────────────────

/// La orden que se abre en el detalle, con equipo y reportes.
final ordenDetalleDemo = _orden(
  id: 'ord-5',
  codigo: 'WO-2024-0892',
  titulo: 'Mantenimiento Preventivo Compresor Atlas Copco GA75',
  zona: 'Planta A - Sección Compresores',
  estado: EstadoOrden.enProgreso,
  prioridad: Prioridad.alta,
  limite: _hoyA(9, 30),
  descripcion: 'Revisión general de filtros de aire, cambio de aceite '
      'sintético y verificación de válvulas de descarga. Se reportó ruido '
      'inusual en el rodamiento principal durante el último turno.',
  equipoId: 'eq-ga75',
  equipoNombre: 'COMPRESOR GA75',
  totalReportes: 3,
);

// SIN USO desde la tajada 2: el feed lee las órdenes de Supabase.
// Borrar en la próxima tajada.
final ordenesDemo = <Orden>[
  _orden(
    id: 'ord-1',
    codigo: 'WO-2024-0891',
    titulo: 'Mantenimiento Preventivo Motor AC',
    zona: 'Línea de Ensamblaje A',
    estado: EstadoOrden.enProgreso,
    prioridad: Prioridad.media,
    limite: _hoyA(8),
  ),
  _orden(
    id: 'ord-2',
    codigo: 'WO-2024-0892',
    titulo: 'Falla en Panel de Control Eléctrico',
    zona: 'Sector de Empaque',
    categoria: 'Eléctrico',
    estado: EstadoOrden.critica,
    prioridad: Prioridad.critica,
    limite: _hoyA(9, 30),
  ),
  _orden(
    id: 'ord-3',
    codigo: 'WO-2024-0893',
    titulo: 'Inspección de Válvula Hidráulica',
    zona: 'Área de Almacén',
    categoria: 'Hidráulico',
    estado: EstadoOrden.pendiente,
    prioridad: Prioridad.baja,
    limite: _hoyA(11, 15),
  ),
  _orden(
    id: 'ord-4',
    codigo: 'WO-2024-0894',
    titulo: 'Reemplazo de Sensores Térmicos',
    zona: 'Planta de Energía',
    categoria: 'Eléctrico',
    estado: EstadoOrden.pendiente,
    prioridad: Prioridad.media,
    limite: _hoyA(13, 45),
  ),
  ordenDetalleDemo,
];

/// Mis Tareas: las órdenes asignadas al usuario actual.
// SIN USO desde la tajada 2: "Mis Tareas" lee de Supabase (asignadasA).
// Borrar en la próxima tajada.
final tareasDemo = <Orden>[
  _orden(
    id: 'tsk-1',
    codigo: 'TSK-1029',
    titulo: 'Engrase de Rodamientos Turbina',
    zona: 'Área de Generación - Nivel 2',
    estado: EstadoOrden.pendiente,
    prioridad: Prioridad.alta,
    limite: _hoyA(16),
  ),
  _orden(
    id: 'tsk-2',
    codigo: 'TSK-1035',
    titulo: 'Calibración de Sensor de Presión',
    zona: 'Línea de Envasado C',
    categoria: 'Inspección',
    estado: EstadoOrden.enProgreso,
    prioridad: Prioridad.media,
    limite: _enDias(1, 9),
  ),
  _orden(
    id: 'tsk-3',
    codigo: 'TSK-1041',
    titulo: 'Inspección de Válvula de Alivio',
    zona: 'Depósito de Químicos',
    categoria: 'Inspección',
    estado: EstadoOrden.pendiente,
    prioridad: Prioridad.critica,
    limite: _hoyA(12, 30),
  ),
  _orden(
    id: 'tsk-4',
    codigo: 'TSK-1048',
    titulo: 'Limpieza de Filtros de Aire',
    zona: 'Sala de Compresores',
    estado: EstadoOrden.validando,
    prioridad: Prioridad.baja,
    limite: _enDias(2, 17),
  ),
];

// ─────────────────────────────────────────────────────────────
// REPORTES (subcolección ordenes/{id}/reportes), indexados por id de orden
// ─────────────────────────────────────────────────────────────

Evidencia _fotoDemo(String nombre, PosicionFoto posicion) => Evidencia(
      posicion: posicion,
      url: nombre,
      thumbUrl: nombre,
      publicId: 'demo/$nombre',
      tomadaEn: _hoyA(8, 15),
    );

Reporte _reporteDemo(String id, String detalles, DateTime cuando,
        {List<Evidencia> evidencias = const []}) =>
    Reporte(
      id: id,
      ordenId: ordenDetalleDemo.id,
      autor: usuarioActualDemo,
      detalles: detalles,
      evidencias: evidencias,
      createdAt: cuando,
    );

final reportesDemo = <String, List<Reporte>>{
  ordenDetalleDemo.id: [
    _reporteDemo('rep-1', 'Inspección visual inicial', _hoyA(8, 15),
        evidencias: [
          _fotoDemo('foto1', PosicionFoto.frontal),
          _fotoDemo('foto2', PosicionFoto.posterior),
        ]),
    _reporteDemo('rep-2', 'Drenaje de aceite usado', _hoyA(9, 30)),
    _reporteDemo('rep-3', 'Limpieza de filtros', _hoyA(10, 45)),
  ],
};

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
