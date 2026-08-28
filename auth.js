// ============================================================
// AUTENTICACIÓN — registro, login, logout y enrutado por rol
// Depende de: supabase-config.js (debe cargarse antes)
// ============================================================

const RUTA_POR_ROL = {
  cliente: "index.html",
  vendedor: "panel-vendedor.html",
  proveedor_servicio: "panel-servicios.html",
  repartidor: "panel-repartidor.html",
  admin: "panel-admin.html",
};

/** Lanza un error legible si Supabase no llegó a configurarse. */
function exigirClienteSupabase() {
  if (!clienteSupabase) {
    throw new Error(
      errorConfiguracionSupabase ||
        "No hay conexión con la base de datos. Recarga la página o revisa tu internet."
    );
  }
}

/**
 * Registra un usuario nuevo en Supabase Auth y deja que el
 * trigger "al_crear_usuario" (ver sql/schema.sql) cree su fila
 * en la tabla perfiles con el rol elegido.
 */
async function registrarUsuario({ email, password, nombre, telefono, cedula, rol }) {
  exigirClienteSupabase();
  const { data, error } = await clienteSupabase.auth.signUp({
    email,
    password,
    options: {
      data: { nombre, telefono, cedula, rol },
    },
  });
  if (error) throw error;
  return data;
}

async function iniciarSesion({ email, password }) {
  exigirClienteSupabase();
  const { data, error } = await clienteSupabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

async function cerrarSesion() {
  if (clienteSupabase) await clienteSupabase.auth.signOut();
  window.location.href = "index.html";
}

/** Devuelve la sesión actual (o null si no hay nadie conectado o no hay conexión). */
async function obtenerSesionActual() {
  if (!clienteSupabase) return null;
  const { data } = await clienteSupabase.auth.getSession();
  return data.session;
}

/** Devuelve la fila de "perfiles" del usuario conectado. */
async function obtenerPerfilActual() {
  const sesion = await obtenerSesionActual();
  if (!sesion) return null;
  const { data, error } = await clienteSupabase
    .from("perfiles")
    .select("*")
    .eq("id", sesion.user.id)
    .single();
  if (error) {
    console.error("No se pudo cargar el perfil:", error.message);
    return null;
  }
  return data;
}

/** Manda a cada usuario a su panel según su rol. */
function irAPanelSegunRol(rol) {
  window.location.href = RUTA_POR_ROL[rol] || "index.html";
}

/**
 * Protege una página: si nadie ha iniciado sesión, redirige a login.
 * Si se pasa rolesPermitidos, además exige que el rol coincida.
 */
async function exigirSesion(rolesPermitidos = null) {
  const perfil = await obtenerPerfilActual();
  if (!perfil) {
    window.location.href = "login.html";
    return null;
  }
  if (rolesPermitidos && !rolesPermitidos.includes(perfil.rol)) {
    window.location.href = "index.html";
    return null;
  }
  return perfil;
}

function botonesInvitado() {
  return `
    <a class="boton boton-secundario" href="login.html">Entrar</a>
    <a class="boton boton-primario" href="registro.html">Crear cuenta</a>
  `;
}

/**
 * Rellena la zona de "nav-usuario" del encabezado según haya o no
 * sesión activa. Se llama en cada página desde su propio script.
 *
 * IMPORTANTE: pinta primero los botones de invitado de forma
 * INMEDIATA (sin esperar respuesta de Supabase). Así, aunque la
 * conexión falle o tarde, el menú nunca se queda vacío — en el peor
 * caso, un usuario ya conectado ve por un instante "Entrar" antes de
 * que se confirme su sesión.
 */
async function pintarBarraUsuario(elementoId = "nav-usuario") {
  const contenedor = document.getElementById(elementoId);
  if (!contenedor) return;

  contenedor.innerHTML = botonesInvitado();

  if (!clienteSupabase) {
    console.error("No se pudo verificar la sesión:", errorConfiguracionSupabase);
    return;
  }

  try {
    const perfil = await obtenerPerfilActual();
    if (!perfil) return; // ya se ven los botones de invitado
    contenedor.innerHTML = `
      <a class="boton boton-secundario" href="${RUTA_POR_ROL[perfil.rol] || "index.html"}">Hola, ${perfil.nombre.split(" ")[0]}</a>
      <button class="boton boton-primario" id="boton-salir">Salir</button>
    `;
    document.getElementById("boton-salir").addEventListener("click", cerrarSesion);
  } catch (err) {
    console.error("No se pudo verificar la sesión:", err.message);
    // se queda con los botones de invitado, que ya están visibles
  }
}
