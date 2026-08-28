// ============================================================
// CONFIGURACIÓN DE SUPABASE
// ------------------------------------------------------------
// 1. Crea un proyecto gratis en https://supabase.com
// 2. Ve a Project Settings > API
// 3. Copia "Project URL" y "anon public key" aquí abajo
// ============================================================

const SUPABASE_URL = "https://TU-PROYECTO.supabase.co";
const SUPABASE_ANON_KEY = "TU-CLAVE-ANON-PUBLICA";

// Cliente global reutilizado por todas las páginas.
// Se crea de forma "defensiva": si la librería de Supabase no llegó a
// cargar (por ejemplo, por una conexión inestable), NO debe romper el
// resto del sitio. En ese caso clienteSupabase queda en null y cada
// pantalla muestra un aviso en vez de quedarse vacía.
let clienteSupabase = null;
let errorConfiguracionSupabase = null;

try {
  if (typeof window.supabase === "undefined") {
    throw new Error(
      "La librería de Supabase no se cargó (revisa tu conexión a internet y recarga la página)."
    );
  }
  if (SUPABASE_URL.includes("TU-PROYECTO") || SUPABASE_ANON_KEY.includes("TU-CLAVE")) {
    throw new Error(
      "Falta configurar supabase-config.js con la URL y la clave de tu propio proyecto de Supabase."
    );
  }
  clienteSupabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
} catch (err) {
  errorConfiguracionSupabase = err.message;
  console.error("Error al conectar con Supabase:", err.message);
}
