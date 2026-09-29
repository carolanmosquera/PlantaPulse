// test_reglas/reglas.test.js
// Pruebas de firestore.rules contra el emulador local (nunca toca producción).
// Ejecutar desde esta carpeta:  npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection, doc, getDoc, getDocs, orderBy, query, serverTimestamp,
  setDoc, Timestamp, updateDoc, where,
} from 'firebase/firestore';

let entorno;

// ── Datos con la misma forma que Usuario.aFirestore() de la app ──
const perfil = (extra = {}) => ({
  nombre: 'Juan Pérez',
  email: 'juan@planta.com',
  rol: 'tecnico',
  especialidad: '',
  plantaId: '',
  zonasAsignadas: [],
  fotoUrl: null,
  turno: '',
  fcmToken: null,
  activo: true,
  createdAt: Timestamp.now(),
  estado: 'pendiente',
  aprobadoPor: null,
  aprobadoEn: null,
  ...extra,
});

const db = (uid) => entorno.authenticatedContext(uid).firestore();

before(async () => {
  entorno = await initializeTestEnvironment({
    projectId: 'demo-plantapulse',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(() => entorno.cleanup());

beforeEach(async () => {
  await entorno.clearFirestore();
  await entorno.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'usuarios/admin1'), perfil({
      nombre: 'Admin', rol: 'admin', plantaId: 'p1', estado: 'activo' }));
    await setDoc(doc(d, 'usuarios/tec1'), perfil({
      nombre: 'Técnico activo', plantaId: 'p1', estado: 'activo' }));
    await setDoc(doc(d, 'usuarios/pend1'), perfil({ nombre: 'Pendiente 1' }));
    await setDoc(doc(d, 'usuarios/pend2'), perfil({ nombre: 'Pendiente 2' }));
    await setDoc(doc(d, 'usuarios/viejo'), (() => {
      // Perfil creado antes de esta tajada: no tiene 'estado'
      const p = perfil({ rol: 'supervisor', plantaId: 'p1' });
      delete p.estado;
      return p;
    })());
    await setDoc(doc(d, 'ordenes/o1'), {
      titulo: 'Cambiar rodamiento', plantaId: 'p1', asignadoAUid: 'tec1' });
  });
});

// ═══════════════ Los cinco casos del simulador ═══════════════

describe('los cinco casos', () => {
  test('1. un pendiente NO puede leer una orden', async () => {
    await assertFails(getDoc(doc(db('pend1'), 'ordenes/o1')));
  });

  test('2. un pendiente SÍ puede crear su propio perfil', async () => {
    await assertSucceeds(setDoc(doc(db('nuevo'), 'usuarios/nuevo'), perfil()));
  });

  test('3. el admin SÍ puede cambiar el estado de otro (aprobar)', async () => {
    await assertSucceeds(updateDoc(doc(db('admin1'), 'usuarios/pend1'), {
      estado: 'activo',
      rol: 'supervisor',
      plantaId: 'p1',
      aprobadoPor: { uid: 'admin1', nombre: 'Admin', fotoUrl: null },
      aprobadoEn: serverTimestamp(),
    }));
  });

  test('4. el admin NO puede asignar rol admin', async () => {
    await assertFails(updateDoc(doc(db('admin1'), 'usuarios/pend1'), {
      estado: 'activo',
      rol: 'admin',
      plantaId: 'p1',
      aprobadoPor: { uid: 'admin1', nombre: 'Admin', fotoUrl: null },
      aprobadoEn: serverTimestamp(),
    }));
  });

  test('5. un técnico activo NO puede cambiar su propio rol', async () => {
    await assertFails(updateDoc(doc(db('tec1'), 'usuarios/tec1'),
      { rol: 'supervisor' }));
  });
});

// ═══════════════ Casos extra que protegen el flujo ═══════════════

describe('registro', () => {
  test('no se puede registrar ya activo', async () => {
    await assertFails(setDoc(doc(db('nuevo'), 'usuarios/nuevo'),
      perfil({ estado: 'activo' })));
  });

  test('no se puede registrar como supervisor', async () => {
    await assertFails(setDoc(doc(db('nuevo'), 'usuarios/nuevo'),
      perfil({ rol: 'supervisor' })));
  });

  test('no se puede registrar con planta ya asignada', async () => {
    await assertFails(setDoc(doc(db('nuevo'), 'usuarios/nuevo'),
      perfil({ plantaId: 'p1' })));
  });

  test('no se puede crear el perfil de otro uid', async () => {
    await assertFails(setDoc(doc(db('nuevo'), 'usuarios/otro'), perfil()));
  });
});

describe('lecturas de usuarios', () => {
  test('un pendiente lee su propio perfil (pantalla de espera)', async () => {
    await assertSucceeds(getDoc(doc(db('pend1'), 'usuarios/pend1')));
  });

  test('un pendiente NO lee a otro pendiente', async () => {
    await assertFails(getDoc(doc(db('pend1'), 'usuarios/pend2')));
  });

  test('un pendiente NO lee a los de la planta', async () => {
    await assertFails(getDoc(doc(db('pend1'), 'usuarios/tec1')));
  });

  test('el admin lista la bandeja de pendientes (misma consulta que la app)', async () => {
    await assertSucceeds(getDocs(query(
      collection(db('admin1'), 'usuarios'),
      where('estado', '==', 'pendiente'),
      orderBy('createdAt', 'desc'))));
  });

  test('un técnico activo NO lista la bandeja de pendientes', async () => {
    await assertFails(getDocs(query(
      collection(db('tec1'), 'usuarios'),
      where('estado', '==', 'pendiente'))));
  });
});

describe('aprobación', () => {
  const firma = { uid: 'admin1', nombre: 'Admin', fotoUrl: null };

  test('el admin SÍ puede rechazar', async () => {
    await assertSucceeds(updateDoc(doc(db('admin1'), 'usuarios/pend1'), {
      estado: 'rechazado', aprobadoPor: firma, aprobadoEn: serverTimestamp() }));
  });

  test('el admin NO aprueba sin planta', async () => {
    await assertFails(updateDoc(doc(db('admin1'), 'usuarios/pend1'), {
      estado: 'activo', rol: 'tecnico', plantaId: '',
      aprobadoPor: firma, aprobadoEn: serverTimestamp() }));
  });

  test('el admin NO puede firmar como otra persona', async () => {
    await assertFails(updateDoc(doc(db('admin1'), 'usuarios/pend1'), {
      estado: 'rechazado',
      aprobadoPor: { uid: 'tec1', nombre: 'Otro', fotoUrl: null },
      aprobadoEn: serverTimestamp() }));
  });

  test('el admin NO puede tocar a un usuario ya activo', async () => {
    await assertFails(updateDoc(doc(db('admin1'), 'usuarios/tec1'), {
      estado: 'rechazado', aprobadoPor: firma, aprobadoEn: serverTimestamp() }));
  });

  test('un pendiente NO puede aprobarse a sí mismo', async () => {
    await assertFails(updateDoc(doc(db('pend1'), 'usuarios/pend1'),
      { estado: 'activo' }));
  });

  test('un técnico activo NO puede aprobar a otros', async () => {
    await assertFails(updateDoc(doc(db('tec1'), 'usuarios/pend1'), {
      estado: 'activo', rol: 'tecnico', plantaId: 'p1',
      aprobadoPor: { uid: 'tec1', nombre: 'T', fotoUrl: null },
      aprobadoEn: serverTimestamp() }));
  });
});

describe('datos de planta', () => {
  test('un técnico activo SÍ lee órdenes de su planta', async () => {
    await assertSucceeds(getDoc(doc(db('tec1'), 'ordenes/o1')));
  });

  test('perfil viejo sin campo estado queda bloqueado (hay que migrarlo)', async () => {
    await assertFails(getDoc(doc(db('viejo'), 'ordenes/o1')));
  });
});
