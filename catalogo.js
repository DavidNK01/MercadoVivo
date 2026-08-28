// ============================================================
// CATÁLOGO PÚBLICO — vista de cliente (index.html)
// ============================================================

const PROVINCIAS_CUBA = [
  "Pinar del Río", "Artemisa", "La Habana", "Mayabeque", "Matanzas",
  "Cienfuegos", "Villa Clara", "Sancti Spíritus", "Ciego de Ávila",
  "Camagüey", "Las Tunas", "Granma", "Holguín", "Santiago de Cuba",
  "Guantánamo", "Isla de la Juventud",
];

const ETIQUETA_TIPO = {
  fisico: "Producto",
  digital: "Digital",
  servicio_domicilio: "Servicio a domicilio",
};

function llenarSelectProvincias(select) {
  PROVINCIAS_CUBA.forEach((p) => {
    const opt = document.createElement("option");
    opt.value = p;
    opt.textContent = p;
    select.appendChild(opt);
  });
}

function tarjetaProducto(item) {
  const tienda = item.tiendas;
  const imagenEstilo = item.imagen_url ? `style="background-image:url('${item.imagen_url}')"` : "";
  return `
    <a class="vitrina" href="producto.html?id=${item.id}">
      <div class="imagen" ${imagenEstilo}>${item.imagen_url ? "" : "Sin imagen"}</div>
      <div class="cuerpo">
        <span class="etiqueta etiqueta-${item.tipo}">${ETIQUETA_TIPO[item.tipo]}</span>
        <div class="titulo">${item.titulo}</div>
        <div class="tienda-nombre">${tienda ? tienda.nombre : "Vendedor"}${tienda && tienda.provincia ? " · " + tienda.provincia : ""}</div>
        <div class="precio">${Number(item.precio).toLocaleString("es-CU")} ${item.moneda}</div>
      </div>
    </a>
  `;
}

async function cargarCatalogo({ texto = "", provincia = "", tipo = "" } = {}) {
  const contenedor = document.getElementById("rejilla-productos");
  contenedor.innerHTML = `<p class="vacio">Cargando vitrinas…</p>`;

  let consulta = clienteSupabase
    .from("productos_servicios")
    .select("*, tiendas(nombre, provincia)")
    .eq("activo", true)
    .order("created_at", { ascending: false })
    .limit(60);

  if (texto) consulta = consulta.ilike("titulo", `%${texto}%`);
  if (tipo) consulta = consulta.eq("tipo", tipo);

  const { data, error } = await consulta;

  if (error) {
    contenedor.innerHTML = `<p class="mensaje-error">No se pudo cargar el catálogo: ${error.message}</p>`;
    return;
  }

  let resultados = data || [];
  if (provincia) {
    resultados = resultados.filter((r) => r.tiendas && r.tiendas.provincia === provincia);
  }

  if (resultados.length === 0) {
    contenedor.innerHTML = `<p class="vacio">Todavía no hay nada que coincida con tu búsqueda. Vuelve pronto — cada día se abren nuevas vitrinas.</p>`;
    return;
  }

  contenedor.innerHTML = resultados.map(tarjetaProducto).join("");
}

document.addEventListener("DOMContentLoaded", () => {
  pintarBarraUsuario();

  const selectProvincia = document.getElementById("filtro-provincia");
  if (selectProvincia) llenarSelectProvincias(selectProvincia);

  cargarCatalogo();

  const form = document.getElementById("form-buscador");
  if (form) {
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      cargarCatalogo({
        texto: document.getElementById("filtro-texto").value.trim(),
        provincia: selectProvincia.value,
        tipo: document.getElementById("filtro-tipo").value,
      });
    });
  }
});
