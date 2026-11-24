// supabase/functions/enviar-push/reglas.ts
//
// Las decisiones de KAN-97 sin red ni base de datos: a quién se le avisa
// y qué dice el aviso. Están aparte para poder probarlas (reglas_test.ts).

/** Usuarios.preferencias_avisos (KAN-100). Faltante = valores por defecto. */
export type Preferencias = {
  push?: boolean;
  mantenimiento?: boolean;
  soloCriticas?: boolean;
};

/** Las columnas de 'ordenes' que usa la función. */
export type OrdenFila = {
  id: string;
  codigo: string;
  titulo: string;
  prioridad: string; // baja | media | alta | critica
  estado: string;
  asignado_a_uid: string | null;
  creado_por: { uid?: string } | null;
  eliminada_en: string | null;
};

/** Las columnas de 'usuarios' que usa la función. */
export type UsuarioFila = {
  id: string;
  fcm_token: string | null;
  preferencias_avisos: Preferencias | null;
  activo: boolean | null;
  estado: string | null;
};

const PRIORIDAD_ALTA = new Set(['alta', 'critica']);

/**
 * Por qué NO se debe avisar, o null si sí se avisa.
 * Devuelve el motivo (y no un booleano) para que la respuesta de la
 * función diga qué pasó cuando se revisan los logs.
 */
export function motivoParaNoAvisar(
  orden: OrdenFila | null,
  usuario: UsuarioFila | null,
): string | null {
  if (!orden) return 'la orden no existe';
  if (orden.eliminada_en) return 'la orden fue eliminada';
  if (!orden.asignado_a_uid) return 'la orden quedó sin responsable';
  // Un supervisor que se asigna una orden a sí mismo no necesita aviso
  if (orden.creado_por?.uid === orden.asignado_a_uid) {
    return 'el responsable es quien creó la orden';
  }
  if (!usuario) return 'el responsable no existe';
  return motivoPorUsuario(usuario, orden.prioridad, 'el responsable');
}

/**
 * Lo que depende solo de quien recibe el aviso: que esté activo, lo que
 * eligió en Ajustes (KAN-100) y que tenga un teléfono registrado.
 * Lo comparten la asignación (KAN-97) y el recordatorio (KAN-95).
 */
function motivoPorUsuario(usuario: UsuarioFila, prioridad: string, quien: string): string | null {
  if (usuario.activo === false || (usuario.estado && usuario.estado !== 'activo')) {
    return `${quien} no está activo`;
  }

  const p = usuario.preferencias_avisos ?? {};
  if (p.push === false) return `${quien} apagó las notificaciones push`;
  // Asignaciones y recordatorios son avisos de órdenes ("mantenimiento" en Ajustes)
  if (p.mantenimiento === false) return `${quien} apagó los avisos de órdenes`;
  if (p.soloCriticas === true && !PRIORIDAD_ALTA.has(prioridad)) {
    return `${quien} solo quiere avisos de prioridad alta o urgente`;
  }

  if (!usuario.fcm_token) return `${quien} no tiene un dispositivo registrado`;
  return null;
}

/** Título y cuerpo de la notificación de asignación. */
export function mensajeAsignacion(orden: OrdenFila): { titulo: string; cuerpo: string } {
  const urgente = orden.prioridad === 'critica';
  return {
    titulo: urgente ? 'Orden urgente asignada' : 'Nueva orden asignada',
    cuerpo: `${orden.codigo} · ${orden.titulo}`,
  };
}

// ── KAN-95: recordatorio de órdenes críticas sin avance ──────────────

/** Una fila de la función SQL public.ordenes_estancadas(). */
export type OrdenEstancada = {
  id: string;
  codigo: string;
  titulo: string;
  planta_id: string;
  prioridad: string;
  estado: string;
  ultimo_avance: string; // último reporte, o la creación si no tiene
};

/**
 * Por qué NO se le recuerda a este supervisor, o null si sí.
 * La orden ya llega filtrada por SQL (crítica, abierta, sin reportes hace
 * más de 4 horas): aquí solo se decide por la persona. Una orden estancada
 * siempre es crítica, así que "solo críticas" nunca la deja por fuera.
 */
export function motivoParaNoRecordar(supervisor: UsuarioFila): string | null {
  return motivoPorUsuario(supervisor, 'critica', 'el supervisor');
}

/** Horas completas desde el último avance hasta 'ahora'. */
export function horasSinAvance(ultimoAvance: string, ahora: Date = new Date()): number {
  return Math.floor((ahora.getTime() - Date.parse(ultimoAvance)) / 3_600_000);
}

/** Título y cuerpo del recordatorio. */
export function mensajeRecordatorio(
  orden: OrdenEstancada,
  ahora: Date = new Date(),
): { titulo: string; cuerpo: string } {
  const horas = horasSinAvance(orden.ultimo_avance, ahora);
  return {
    titulo: 'Orden crítica sin avance',
    cuerpo: `${orden.codigo} · ${orden.titulo} lleva ${horas} h sin reportes`,
  };
}
