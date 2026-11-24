// Proxy de IA de PlantaPulse.
// Estructura notas, redacta reportes, resume turnos y estima el progreso
// de una orden usando Gemini.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

const TIPOS = [
  "estructurar_orden",
  "redactar_reporte",
  "resumen_turno",
  "progreso_orden",
] as const;
type Tipo = (typeof TIPOS)[number];

const CLAVE = Deno.env.get("GEMINI_API_KEY") ?? "";
const USAR_FALSAS = Deno.env.get("IA_FALSA") === "1";
const MODELO = "gemini-3.1-flash-lite";
const URL_GEMINI = "https://generativelanguage.googleapis.com/v1beta/interactions";

function json(cuerpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(cuerpo), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

// Respaldo para la demo: con IA_FALSA=1 la función responde esto sin
// llamar a ningún modelo.
const FALSAS: Record<Tipo, unknown> = {
  estructurar_orden: {
    titulo: "Ruido anómalo en banda transportadora 2",
    descripcion:
      "Se reporta un ruido no habitual acompañado de olor a quemado. " +
      "Requiere inspección del motor y de los rodamientos.",
    categoria_sugerida: "Mecánico",
    prioridad_sugerida: "alta",
  },
  redactar_reporte: {
    texto:
      "Se realizó la intervención sobre el equipo. Se verificó el estado " +
      "de los componentes y se dejó en condiciones de operación.",
  },
  resumen_turno: {
    vinetas: [
      "El turno cierra con más órdenes resueltas que abiertas.",
      "La zona de empaque concentra la mayor parte de las intervenciones.",
      "Hay una orden crítica próxima a vencer.",
    ],
  },
  progreso_orden: {
    porcentaje: 60,
    resumen:
      "Se desmontó el equipo y se identificó el rodamiento dañado. " +
      "El repuesto ya fue solicitado.",
    falta:
      "Instalar el repuesto y hacer la prueba de funcionamiento. " +
      "Si el repuesto llega a tiempo, podría cerrarse en uno o dos días.",
  },
};

const ESQUEMAS: Record<Tipo, unknown> = {
  estructurar_orden: {
    type: "object",
    properties: {
      titulo: { type: "string" },
      descripcion: { type: "string" },
      categoria_sugerida: { type: "string" },
      prioridad_sugerida: { type: "string", enum: ["baja", "media", "alta"] },
    },
    required: ["titulo", "descripcion", "categoria_sugerida", "prioridad_sugerida"],
  },
  redactar_reporte: {
    type: "object",
    properties: { texto: { type: "string" } },
    required: ["texto"],
  },
  resumen_turno: {
    type: "object",
    properties: { vinetas: { type: "array", items: { type: "string" } } },
    required: ["vinetas"],
  },
  progreso_orden: {
    type: "object",
    properties: {
      porcentaje: { type: "integer", minimum: 0, maximum: 100 },
      resumen: { type: "string" },
      falta: { type: "string" },
    },
    required: ["porcentaje", "resumen", "falta"],
  },
};

// Los prompts viven aquí: cambiarlos es desplegar, no recompilar la app.
function construirPrompt(tipo: Tipo, datos: Record<string, unknown>): string {
  const recortar = (v: unknown) => String(v ?? "").slice(0, 2000);

  switch (tipo) {
    case "estructurar_orden":
      return [
        "Eres un asistente de mantenimiento industrial.",
        "Convierte esta nota informal de un supervisor en una orden de trabajo.",
        "El título debe ser técnico y describir el problema, no la solución.",
        "Responde en español.",
        "",
        `Nota: ${recortar(datos.nota)}`,
      ].join("\n");

    case "redactar_reporte":
      return [
        "Eres un técnico de mantenimiento industrial redactando un reporte.",
        "Convierte estas notas sueltas en un reporte breve y profesional.",
        "No inventes acciones que no estén en las notas.",
        "Responde en español.",
        "",
        `Equipo: ${recortar(datos.equipo)}`,
        `Notas: ${recortar(datos.notas)}`,
      ].join("\n");

    case "resumen_turno":
      return [
        "Eres un supervisor de planta resumiendo el turno.",
        "Escribe exactamente tres viñetas cortas interpretando estas cifras.",
        "No inventes cifras distintas de las que te doy.",
        "Responde en español.",
        "",
        `Cifras: ${JSON.stringify(datos.cifras ?? {})}`,
      ].join("\n");

    case "progreso_orden":
      // Es una ESTIMACIÓN para orientar al supervisor, y la app lo dice así.
      // Los reportes pueden ser largos: se recorta el JSON completo.
      return [
        "Eres un supervisor de mantenimiento industrial revisando una orden.",
        "Con la orden y sus reportes de avance (del más antiguo al más reciente),",
        "estima qué porcentaje del trabajo está hecho (entero de 0 a 100),",
        "resume en dos o tres frases lo que ya se hizo, y di qué podría faltar",
        "y cuánto tiempo aproximado podría tomar, si los reportes lo permiten.",
        "Básate SOLO en los reportes. 100 solo si no queda nada pendiente.",
        "Si hay un bloqueo (por ejemplo, falta un repuesto), dilo en lo que falta.",
        "No inventes trabajos que no aparezcan en los reportes.",
        "Responde en español.",
        "",
        `Orden: ${JSON.stringify(datos.orden ?? {}).slice(0, 2000)}`,
        `Reportes: ${JSON.stringify(datos.reportes ?? []).slice(0, 8000)}`,
      ].join("\n");
  }
}

async function llamarGemini(tipo: Tipo, datos: Record<string, unknown>) {
  const respuesta = await fetch(URL_GEMINI, {
    method: "POST",
    headers: { "x-goog-api-key": CLAVE, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: MODELO,
      input: construirPrompt(tipo, datos),
      response_format: {
        type: "text",
        mime_type: "application/json",
        schema: ESQUEMAS[tipo],
      },
    }),
  });

  if (respuesta.status === 429) {
    throw { codigo: 429, mensaje: "Se agotó la cuota del asistente por hoy." };
  }
  if (!respuesta.ok) {
    console.error("gemini", respuesta.status, await respuesta.text());
    throw { codigo: 502, mensaje: "El asistente no está disponible ahora." };
  }

  const crudo = await respuesta.json();

  if (crudo.status !== "completed") {
    console.error("estado inesperado:", crudo.status);
    throw { codigo: 502, mensaje: "El asistente no terminó la respuesta." };
  }

  console.log("tokens:", crudo.usage?.total_tokens);

  // steps[] trae primero un paso 'thought' y después 'model_output',
  // así que hay que filtrar por tipo y no tomar el índice 0.
  const salida = crudo.steps?.find(
    (p: { type?: string }) => p.type === "model_output",
  );
  const texto = salida?.content?.find(
    (c: { type?: string }) => c.type === "text",
  )?.text;

  if (typeof texto !== "string") {
    console.error("sin texto:", JSON.stringify(crudo).slice(0, 500));
    throw { codigo: 502, mensaje: "El asistente devolvió una respuesta vacía." };
  }

  try {
    return JSON.parse(texto);
  } catch {
    console.error("no parsea:", texto.slice(0, 300));
    throw { codigo: 502, mensaje: "El asistente devolvió una respuesta ilegible." };
  }
}

export default {
  // 'user': solo con sesión iniciada. NO uses 'publishable': esa clave
  // viaja dentro del APK y cualquiera podría gastar la cuota de Gemini.
  fetch: withSupabase({ auth: "user" }, async (req: Request, ctx) => {
    if (req.method !== "POST") {
      return json({ error: "Método no permitido" }, 405);
    }

    let cuerpo: { tipo?: string; datos?: Record<string, unknown> };
    try {
      cuerpo = await req.json();
    } catch {
      return json({ error: "El cuerpo de la petición no es JSON válido" }, 400);
    }

    const tipo = cuerpo.tipo as Tipo;
    if (!TIPOS.includes(tipo)) {
      return json({ error: `Tipo de tarea no reconocido: ${cuerpo.tipo}` }, 400);
    }

    console.log("uid:", ctx.userClaims?.sub, "· tipo:", tipo);

    if (USAR_FALSAS) return json(FALSAS[tipo]);

    try {
      return json(await llamarGemini(tipo, cuerpo.datos ?? {}));
    } catch (e) {
      const err = e as { codigo?: number; mensaje?: string };
      return json(
        { error: err.mensaje ?? "No se pudo completar la solicitud." },
        err.codigo ?? 500,
      );
    }
  }),
};