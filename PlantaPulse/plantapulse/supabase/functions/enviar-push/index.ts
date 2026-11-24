// supabase/functions/enviar-push/index.ts
//
// Notificaciones push de órdenes. Al tocar cualquiera, la app abre la
// orden que menciona (KAN-96, con 'orden_id'). Dos tipos de aviso:
//
//   {tipo: 'asignacion', orden_id}  KAN-97: al técnico al que le asignan
//                                   una orden. La llama el trigger de
//                                   supabase/06_push_asignacion.sql.
//   {tipo: 'estancadas'}            KAN-95: a los supervisores, por cada
//                                   orden crítica con más de 4 horas sin
//                                   reportes. La llama cada 15 minutos el
//                                   cron de supabase/07_recordatorios_estancadas.sql.
//
// Las dos llamadas traen el header x-webhook-secret: nadie más puede usarla.
//
// Secretos (supabase secrets set ...):
//   FCM_SERVICE_ACCOUNT  JSON de la cuenta de servicio de Firebase
//   PUSH_WEBHOOK_SECRET  el mismo valor guardado en el Vault de la base
// SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY los pone Supabase solo.
import { createClient } from 'npm:@supabase/supabase-js@2';
import { importPKCS8, SignJWT } from 'npm:jose@5';
import {
  mensajeAsignacion,
  mensajeRecordatorio,
  motivoParaNoAvisar,
  motivoParaNoRecordar,
  type OrdenEstancada,
  type OrdenFila,
  type UsuarioFila,
} from './reglas.ts';

const SECRETO = Deno.env.get('PUSH_WEBHOOK_SECRET') ?? '';
const CUENTA_JSON = Deno.env.get('FCM_SERVICE_ACCOUNT') ?? '';

// KAN-95: horas sin reportes para considerar estancada una orden crítica
const HORAS_SIN_AVANCE = 4;

// service_role: la función lee el token de otro usuario, cosa que RLS no
// le permite a nadie desde la app. Esta clave nunca sale del servidor.
const db = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  { auth: { persistSession: false } },
);

type Cuenta = { project_id: string; client_email: string; private_key: string };

// ── Token de acceso de Google (dura 1 hora; se reutiliza mientras sirva) ──

let tokenGoogle: { valor: string; vence: number } | null = null;

async function accesoGoogle(cuenta: Cuenta): Promise<string> {
  const ahora = Math.floor(Date.now() / 1000);
  if (tokenGoogle && tokenGoogle.vence - 60 > ahora) return tokenGoogle.valor;

  const llave = await importPKCS8(cuenta.private_key, 'RS256');
  const assertion = await new SignJWT({ scope: 'https://www.googleapis.com/auth/firebase.messaging' })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(cuenta.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(ahora)
    .setExpirationTime(ahora + 3600)
    .sign(llave);

  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!r.ok) throw new Error(`Google rechazó la cuenta de servicio: ${r.status} ${await r.text()}`);
  const { access_token, expires_in } = await r.json();
  tokenGoogle = { valor: access_token, vence: ahora + Number(expires_in ?? 3600) };
  return access_token;
}

// ── Envío por la API HTTP v1 de Firebase Cloud Messaging ──

type ResultadoEnvio = { ok: true } | { ok: false; tokenInvalido: boolean; detalle: string };

async function enviarFcm(
  cuenta: Cuenta,
  token: string,
  titulo: string,
  cuerpo: string,
  datos: Record<string, string>,
): Promise<ResultadoEnvio> {
  const r = await fetch(
    `https://fcm.googleapis.com/v1/projects/${cuenta.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${await accesoGoogle(cuenta)}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          // 'notification' hace que Android la muestre solo con la app cerrada
          notification: { title: titulo, body: cuerpo },
          // 'data' es lo que lee la app al tocarla (PushRepositorioImpl)
          data: datos,
          android: { priority: 'HIGH' },
        },
      }),
    },
  );
  if (r.ok) return { ok: true };

  const detalle = await r.text();
  // El teléfono desinstaló la app o el token caducó: hay que olvidarlo
  const tokenInvalido = r.status === 404 || detalle.includes('UNREGISTERED');
  return { ok: false, tokenInvalido, detalle };
}

const responder = (estado: number, cuerpo: Record<string, unknown>) =>
  new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { 'Content-Type': 'application/json' },
  });

const COLUMNAS_USUARIO = 'id, fcm_token, preferencias_avisos, activo, estado';

/** Si el teléfono ya no es válido, se borra el token para no reintentar. */
async function olvidarTokenSiInvalido(resultado: ResultadoEnvio, usuarioId: string) {
  if (!resultado.ok && resultado.tokenInvalido) {
    await db.from('usuarios').update({ fcm_token: null }).eq('id', usuarioId);
  }
}

// ── KAN-97: aviso al técnico asignado ─────────────────────────────────

async function avisarAsignacion(cuenta: Cuenta, ordenId: string): Promise<Response> {
  // La orden se lee de nuevo: el trigger solo manda el id, y así el aviso
  // usa los datos que hay en la base en este momento.
  const { data: orden, error: errorOrden } = await db
    .from('ordenes')
    .select('id, codigo, titulo, prioridad, estado, asignado_a_uid, creado_por, eliminada_en')
    .eq('id', ordenId)
    .maybeSingle<OrdenFila>();
  if (errorOrden) return responder(500, { error: errorOrden.message });

  let usuario: UsuarioFila | null = null;
  if (orden?.asignado_a_uid) {
    const { data, error } = await db
      .from('usuarios')
      .select(COLUMNAS_USUARIO)
      .eq('id', orden.asignado_a_uid)
      .maybeSingle<UsuarioFila>();
    if (error) return responder(500, { error: error.message });
    usuario = data;
  }

  const motivo = motivoParaNoAvisar(orden, usuario);
  if (motivo) return responder(200, { enviado: false, motivo });

  const { titulo, cuerpo } = mensajeAsignacion(orden!);
  const resultado = await enviarFcm(cuenta, usuario!.fcm_token!, titulo, cuerpo, {
    tipo: 'asignacion',
    orden_id: orden!.id,
  });
  await olvidarTokenSiInvalido(resultado, usuario!.id);

  if (!resultado.ok) {
    return responder(502, { enviado: false, motivo: 'FCM rechazó el envío', detalle: resultado.detalle });
  }
  return responder(200, { enviado: true, orden_id: orden!.id });
}

// ── KAN-95: recordatorio a los supervisores ───────────────────────────

async function recordarEstancadas(cuenta: Cuenta): Promise<Response> {
  // Qué órdenes están estancadas lo decide SQL (ver 07_recordatorios_estancadas.sql):
  // críticas, abiertas, sin reportes hace más de 4 horas y sin recordatorio
  // reciente. Aquí solo se decide a quién se le avisa y se envía.
  const { data, error } = await db.rpc('ordenes_estancadas', { horas: HORAS_SIN_AVANCE });
  if (error) return responder(500, { error: error.message });
  const ordenes = (data ?? []) as OrdenEstancada[];

  const resumen: Record<string, unknown>[] = [];
  for (const orden of ordenes) {
    const { data: supervisores, error: errorSup } = await db
      .from('usuarios')
      .select(COLUMNAS_USUARIO)
      .eq('planta_id', orden.planta_id)
      .eq('rol', 'supervisor')
      .returns<UsuarioFila[]>();
    if (errorSup) return responder(500, { error: errorSup.message });

    const { titulo, cuerpo } = mensajeRecordatorio(orden);
    let enviados = 0;
    const omitidos: string[] = [];
    for (const supervisor of supervisores ?? []) {
      const motivo = motivoParaNoRecordar(supervisor);
      if (motivo) {
        omitidos.push(motivo);
        continue;
      }
      const resultado = await enviarFcm(cuenta, supervisor.fcm_token!, titulo, cuerpo, {
        tipo: 'recordatorio',
        orden_id: orden.id,
      });
      await olvidarTokenSiInvalido(resultado, supervisor.id);
      if (resultado.ok) enviados++;
    }

    // Se marca aunque nadie lo haya recibido: así no se reintenta cada
    // 15 minutos. El siguiente recordatorio sale si la orden sigue sin
    // reportes 4 horas más (o si recibe un reporte y se vuelve a estancar).
    const { error: errorMarca } = await db
      .from('recordatorios_estancadas')
      .upsert({ orden_id: orden.id, enviado_en: new Date().toISOString() });
    if (errorMarca) return responder(500, { error: errorMarca.message });

    resumen.push({ orden_id: orden.id, codigo: orden.codigo, enviados, omitidos });
  }
  return responder(200, { revisadas: ordenes.length, ordenes: resumen });
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return responder(405, { error: 'Solo POST' });
  if (!SECRETO || req.headers.get('x-webhook-secret') !== SECRETO) {
    return responder(401, { error: 'No autorizado' });
  }
  if (!CUENTA_JSON) return responder(500, { error: 'Falta el secreto FCM_SERVICE_ACCOUNT' });

  let solicitud: { tipo?: string; orden_id?: string };
  try {
    solicitud = await req.json();
  } catch {
    return responder(400, { error: 'El cuerpo no es JSON' });
  }
  const cuenta = JSON.parse(CUENTA_JSON) as Cuenta;
  if (solicitud.tipo === 'asignacion' && typeof solicitud.orden_id === 'string') {
    return avisarAsignacion(cuenta, solicitud.orden_id);
  }
  if (solicitud.tipo === 'estancadas') {
    return recordarEstancadas(cuenta);
  }
  return responder(400, {
    error: 'Se esperaba {tipo: "asignacion", orden_id} o {tipo: "estancadas"}',
  });
});
