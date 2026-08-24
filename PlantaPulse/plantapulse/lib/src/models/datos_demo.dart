// lib/src/models/datos_demo.dart
import 'orden.dart';
import 'alerta.dart';

const ordenesDemo = <Orden>[
  Orden(
    codigo: 'WO-2024-0891',
    titulo: 'Mantenimiento Preventivo Motor AC',
    ubicacion: 'Línea de Ensamblaje A',
    estado: EstadoOrden.enProgreso,
    hora: '08:00 AM',
    prioridad: 'Media',
  ),
  Orden(
    codigo: 'WO-2024-0892',
    titulo: 'Falla en Panel de Control Eléctrico',
    ubicacion: 'Sector de Empaque',
    estado: EstadoOrden.critica,
    hora: '09:30 AM',
    prioridad: 'Urgente',
  ),
  Orden(
    codigo: 'WO-2024-0893',
    titulo: 'Inspección de Válvula Hidráulica',
    ubicacion: 'Área de Almacén',
    estado: EstadoOrden.pendiente,
    hora: '11:15 AM',
    prioridad: 'Baja',
  ),
  Orden(
    codigo: 'WO-2024-0894',
    titulo: 'Reemplazo de Sensores Térmicos',
    ubicacion: 'Planta de Energía',
    estado: EstadoOrden.pendiente,
    hora: '01:45 PM',
    prioridad: 'Media',
  ),

  Orden(
    codigo: 'WO-2024-0892',
    titulo: 'Mantenimiento Preventivo Compresor Atlas Copco GA75',
    ubicacion: 'Planta A - Sección Compresores',
    estado: EstadoOrden.enProgreso,
    hora: '09:30 AM',
    prioridad: 'Alta',
    descripcion: 'Revisión general de filtros de aire, cambio de aceite '
        'sintético y verificación de válvulas de descarga. Se reportó ruido '
        'inusual en el rodamiento principal durante el último turno.',
    asignadoA: 'ING. CARLOS MENDOZA',
    creadoEn: '2024-05-20 08:00',
    fotos: ['foto1', 'foto2'],
    equipo: Equipo(
      nombre: 'COMPRESOR GA75',
      serial: 'AC-88291-K',
      modelo: '2022',
    ),
    actividades: [
      PasoActividad(titulo: 'Inspección visual inicial',
        tecnico: 'Téc: C. Mendoza', hora: '08:15', completado: true),
      PasoActividad(titulo: 'Drenaje de aceite usado',
        tecnico: 'Téc: C. Mendoza', hora: '09:30', completado: true),
      PasoActividad(titulo: 'Limpieza de filtros',
        tecnico: 'Téc: C. Mendoza', hora: '10:45', completado: true),
      PasoActividad(titulo: 'Reemplazo de rodamiento',
        tecnico: 'Téc: C. Mendoza', hora: '---', completado: false),
    ],
  ),

];

const alertasDemo = <Alerta>[
  Alerta(tipo: TipoAlerta.critica, titulo: 'FALLA CRÍTICA DETECTADA',
    descripcion: 'Sensor de temperatura en Turbina-04 ha superado el límite operativo (105°C).',
    hora: '10:45 AM', codigo: 'OT-8842', noLeida: true, grupo: 'HOY'),
  Alerta(tipo: TipoAlerta.preventiva, titulo: 'MANTENIMIENTO PREVENTIVO',
    descripcion: 'La inspección mensual de la Cinta Transportadora B está programada.',
    hora: '09:15 AM', noLeida: true, grupo: 'HOY'),
  Alerta(tipo: TipoAlerta.completada, titulo: 'ORDEN DE TRABAJO',
    descripcion: 'La reparación del Motor Sincrónico M-12 ha sido validada por el supervisor.',
    hora: '08:30 AM', codigo: 'OT-8839', grupo: 'HOY'),
  Alerta(tipo: TipoAlerta.info, titulo: 'ACTUALIZACIÓN DE MANUAL',
    descripcion: 'Se ha actualizado el manual de seguridad para el manejo de químicos en zona C.',
    hora: '04:20 PM', grupo: 'AYER'),
  Alerta(tipo: TipoAlerta.critica, titulo: 'BAJA PRESIÓN DE ACEITE',
    descripcion: 'Alerta de sistema en Compresor Principal. Se requiere revisión de niveles.',
    hora: '11:10 AM', codigo: 'OT-8835', grupo: 'AYER'),
  Alerta(tipo: TipoAlerta.completada, titulo: 'REEMPLAZO DE FILTROS',
    descripcion: 'Sistemas de ventilación primaria operando al 100% tras cambio de componentes.',
    hora: 'Lun, 15:00', codigo: 'OT-8821', grupo: 'ESTA SEMANA'),
];

const tareasDemo = <Orden>[
  Orden(codigo: 'TSK-1029', titulo: 'Engrase de Rodamientos Turbina',
    ubicacion: 'Área de Generación - Nivel 2', estado: EstadoOrden.pendiente,
    hora: 'Hoy, 16:00', prioridad: 'Alta'),
  Orden(codigo: 'TSK-1035', titulo: 'Calibración de Sensor de Presión',
    ubicacion: 'Línea de Envasado C', estado: EstadoOrden.enProgreso,
    hora: '24 May, 09:00', prioridad: 'Media'),
  Orden(codigo: 'TSK-1041', titulo: 'Inspección de Válvula de Alivio',
    ubicacion: 'Depósito de Químicos', estado: EstadoOrden.pendiente,
    hora: 'Hoy, 12:30', prioridad: 'Urgente'),
  Orden(codigo: 'TSK-1048', titulo: 'Limpieza de Filtros de Aire',
    ubicacion: 'Sala de Compresores', estado: EstadoOrden.validando,
    hora: '25 May, 17:00', prioridad: 'Baja'),
];

