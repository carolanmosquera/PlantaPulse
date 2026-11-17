// supabase/functions/enviar-push/reglas_test.ts
// deno test supabase/functions/enviar-push/reglas_test.ts
import { mensajeAsignacion, motivoParaNoAvisar, type OrdenFila, type UsuarioFila } from './reglas.ts';

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
