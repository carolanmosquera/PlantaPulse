// supabase/functions/enviar-push/reglas_test.ts
// deno test supabase/functions/enviar-push/reglas_test.ts
import {
  horasSinAvance,
  mensajeAsignacion,
  mensajeRecordatorio,
  motivoParaNoAvisar,
  motivoParaNoRecordar,
  type OrdenEstancada,
  type OrdenFila,
  type UsuarioFila,
} from './reglas.ts';

function iguales(real: unknown, esperado: unknown) {
  if (JSON.stringify(real) !== JSON.stringify(esperado)) {
    throw new Error(`Esperaba ${JSON.stringify(esperado)} y llegó ${JSON.stringify(real)}`);
  }
}

const orden = (cambios: Partial<OrdenFila> = {}): OrdenFila => ({
  id: 'o1',
  codigo: 'ORD-0042',
  titulo: 'Fuga en la caldera 2',
  prioridad: 'media',
  estado: 'pendiente',
  asignado_a_uid: 'tec1',
  creado_por: { uid: 'sup1' },
  eliminada_en: null,
  ...cambios,
});

const tecnico = (cambios: Partial<UsuarioFila> = {}): UsuarioFila => ({
  id: 'tec1',
  fcm_token: 'token-1',
  preferencias_avisos: { push: true, mantenimiento: true, soloCriticas: false },
  activo: true,
  estado: 'activo',
  ...cambios,
});

Deno.test('avisa al técnico asignado', () => {
  iguales(motivoParaNoAvisar(orden(), tecnico()), null);
});

Deno.test('sin preferencias guardadas se usan las de por defecto (avisar)', () => {
  iguales(motivoParaNoAvisar(orden(), tecnico({ preferencias_avisos: null })), null);
});

Deno.test('no avisa si el técnico no tiene dispositivo registrado', () => {
  iguales(
    motivoParaNoAvisar(orden(), tecnico({ fcm_token: null })),
    'el responsable no tiene un dispositivo registrado',
  );
});

Deno.test('respeta Ajustes: push apagado', () => {
  iguales(
    motivoParaNoAvisar(orden(), tecnico({ preferencias_avisos: { push: false } })),
    'el responsable apagó las notificaciones push',
  );
});

Deno.test('respeta Ajustes: avisos de órdenes apagados', () => {
  iguales(
    motivoParaNoAvisar(orden(), tecnico({ preferencias_avisos: { mantenimiento: false } })),
    'el responsable apagó los avisos de órdenes',
  );
});

Deno.test('respeta Ajustes: solo críticas deja pasar alta y urgente, no media', () => {
  const soloCriticas = tecnico({ preferencias_avisos: { soloCriticas: true } });
  iguales(
    motivoParaNoAvisar(orden({ prioridad: 'media' }), soloCriticas),
    'el responsable solo quiere avisos de prioridad alta o urgente',
  );
  iguales(motivoParaNoAvisar(orden({ prioridad: 'alta' }), soloCriticas), null);
  iguales(motivoParaNoAvisar(orden({ prioridad: 'critica' }), soloCriticas), null);
});

Deno.test('no avisa si quien crea la orden se la asigna a sí mismo', () => {
  iguales(
    motivoParaNoAvisar(orden({ creado_por: { uid: 'tec1' } }), tecnico()),
    'el responsable es quien creó la orden',
  );
});

Deno.test('no avisa por órdenes eliminadas ni sin responsable', () => {
  iguales(motivoParaNoAvisar(orden({ eliminada_en: '2026-11-15T10:00:00Z' }), tecnico()), 'la orden fue eliminada');
  iguales(motivoParaNoAvisar(orden({ asignado_a_uid: null }), tecnico()), 'la orden quedó sin responsable');
  iguales(motivoParaNoAvisar(null, tecnico()), 'la orden no existe');
});

Deno.test('no avisa a un usuario inactivo', () => {
  iguales(motivoParaNoAvisar(orden(), tecnico({ activo: false })), 'el responsable no está activo');
});

Deno.test('el mensaje dice código y título, y marca las urgentes', () => {
  iguales(mensajeAsignacion(orden()), { titulo: 'Nueva orden asignada', cuerpo: 'ORD-0042 · Fuga en la caldera 2' });
  iguales(mensajeAsignacion(orden({ prioridad: 'critica' })).titulo, 'Orden urgente asignada');
});

// ── KAN-95: recordatorio de órdenes críticas sin avance ──────────────

const supervisor = (cambios: Partial<UsuarioFila> = {}): UsuarioFila => ({
  id: 'sup1',
  fcm_token: 'token-sup',
  preferencias_avisos: { push: true, mantenimiento: true, soloCriticas: false },
  activo: true,
  estado: 'activo',
  ...cambios,
});

const estancada: OrdenEstancada = {
  id: 'o9',
  codigo: 'ORD-0099',
  titulo: 'Compresor detenido',
  planta_id: 'p1',
  prioridad: 'critica',
  estado: 'en_progreso',
  ultimo_avance: '2026-11-23T08:00:00Z',
};

Deno.test('recordatorio: avisa al supervisor activo con teléfono', () => {
  iguales(motivoParaNoRecordar(supervisor()), null);
});

Deno.test('recordatorio: "solo críticas" no lo deja por fuera, porque la orden es crítica', () => {
  iguales(motivoParaNoRecordar(supervisor({ preferencias_avisos: { soloCriticas: true } })), null);
});

Deno.test('recordatorio: respeta push y avisos de órdenes apagados', () => {
  iguales(
    motivoParaNoRecordar(supervisor({ preferencias_avisos: { push: false } })),
    'el supervisor apagó las notificaciones push',
  );
  iguales(
    motivoParaNoRecordar(supervisor({ preferencias_avisos: { mantenimiento: false } })),
    'el supervisor apagó los avisos de órdenes',
  );
});

Deno.test('recordatorio: no avisa sin teléfono ni a un supervisor inactivo', () => {
  iguales(
    motivoParaNoRecordar(supervisor({ fcm_token: null })),
    'el supervisor no tiene un dispositivo registrado',
  );
  iguales(motivoParaNoRecordar(supervisor({ estado: 'pendiente' })), 'el supervisor no está activo');
});

Deno.test('recordatorio: cuenta las horas completas sin avance', () => {
  iguales(horasSinAvance('2026-11-23T08:00:00Z', new Date('2026-11-23T12:59:00Z')), 4);
  iguales(horasSinAvance('2026-11-23T08:00:00Z', new Date('2026-11-23T14:00:00Z')), 6);
});

Deno.test('recordatorio: el mensaje dice la orden y cuántas horas lleva', () => {
  iguales(mensajeRecordatorio(estancada, new Date('2026-11-23T13:10:00Z')), {
    titulo: 'Orden crítica sin avance',
    cuerpo: 'ORD-0099 · Compresor detenido lleva 5 h sin reportes',
  });
});
