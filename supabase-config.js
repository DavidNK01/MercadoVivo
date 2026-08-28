// ============================================================
// CONFIGURACIÓN DE SUPABASE
// ------------------------------------------------------------
// 1. Crea un proyecto gratis en https://supabase.com
// 2. Ve a Project Settings > API
// 3. Copia "Project URL" y "anon public key" aquí abajo
// ============================================================

const SUPABASE_URL = "https://ujpgsamhdiutpobsttbr.supabase.co/rest/v1/";
const SUPABASE_ANON_KEY = "sb_publishable_zZWj1gWvTCBUmxKr2odusg_aymMYInl";

// Cliente global reutilizado por todas las páginas.
// Requiere que el <script> de supabase-js se cargue ANTES que este archivo.
const clienteSupabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
