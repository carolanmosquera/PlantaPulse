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
  if (usuario.activo === false || (usuario.estado && usuario.estado !== 'activo')) {
    return 'el responsable no está activo';
  }

  const p = usuario.preferencias_avisos ?? {};
  if (p.push === false) return 'el responsable apagó las notificaciones push';
  // Una asignación es un aviso de órdenes ("mantenimiento" en Ajustes)
  if (p.mantenimiento === false) return 'el responsable apagó los avisos de órdenes';
  if (p.soloCriticas === true && !PRIORIDAD_ALTA.has(orden.prioridad)) {
    return 'el responsable solo quiere avisos de prioridad alta o urgente';
  }

  if (!usuario.fcm_token) return 'el responsable no tiene un dispositivo registrado';
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
