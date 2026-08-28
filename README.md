# Vitrina — Marketplace + Servicios + Mensajería para Cuba

Plataforma que conecta vendedores, prestadores de servicio y repartidores con clientes.
Frontend estático (funciona gratis en **GitHub Pages**) + backend gratuito en **Supabase**
(base de datos PostgreSQL real, autenticación y almacenamiento de archivos).

## Estado del proyecto — Fase 1 de varias

Esta primera entrega incluye:
- Esquema completo de base de datos con seguridad por filas (RLS) — `sql/schema.sql`
- Sistema de registro e inicio de sesión con 4 roles (cliente, vendedor, prestador de servicio, repartidor)
- Catálogo público con buscador y filtros por provincia y tipo

Lo que falta (próximas fases): panel de vendedor (subir productos, gestionar pedidos),
panel de repartidor (solicitudes cercanas, PIN de entrega), panel de prestador de
servicios, panel de administración, checkout/pago y sistema de reseñas visible.
La base de datos y las políticas de seguridad para todo eso **ya están** en `schema.sql`,
así que las siguientes fases solo agregan pantallas.

---

## Paso 1 — Crear el proyecto en Supabase (gratis)

1. Ve a [supabase.com](https://supabase.com) y crea una cuenta gratuita.
2. Crea un proyecto nuevo (elige la región más cercana, por ejemplo EE.UU. Este).
3. Cuando el proyecto esté listo, entra a **SQL Editor** (menú lateral).
4. Abre el archivo `sql/schema.sql` de este repositorio, copia todo su contenido,
   pégalo en el editor y presiona **Run**. Esto crea todas las tablas, roles y reglas
   de seguridad.
5. Ve a **Project Settings → API**. Copia dos valores:
   - **Project URL**
   - **anon public key**

## Paso 2 — Conectar el frontend con Supabase

1. Abre `js/supabase-config.js` en este repositorio.
2. Reemplaza:
   ```js
   const SUPABASE_URL = "https://TU-PROYECTO.supabase.co";
   const SUPABASE_ANON_KEY = "TU-CLAVE-ANON-PUBLICA";
   ```
   con los valores que copiaste en el paso anterior.
3. Guarda el archivo.

## Paso 3 — Publicar gratis en GitHub Pages

1. Sube todos los archivos de esta carpeta a un repositorio nuevo en GitHub
   (deben quedar en la **raíz** del repositorio: `index.html` visible directamente,
   no dentro de una subcarpeta).
2. En el repositorio, ve a **Settings → Pages**.
3. En "Source" elige la rama `main` y la carpeta `/ (root)`. Guarda.
4. En un par de minutos tu sitio estará disponible en
   `https://tu-usuario.github.io/nombre-del-repositorio/`.

## Paso 4 — Confirmar que funciona

1. Entra a tu sitio publicado y crea una cuenta de prueba como "vendedor".
2. Revisa tu correo y confirma la cuenta (Supabase envía el correo automáticamente).
3. Inicia sesión. Como todavía no existe el panel de vendedor, te llevará a
   `panel-vendedor.html`, que se agrega en la próxima fase.
4. Para probar el catálogo ahora mismo, puedes insertar una fila de prueba
   directamente en Supabase: **Table Editor → tiendas** (crea una tienda apuntando
   a tu perfil) y luego **Table Editor → productos_servicios** (crea un producto
   apuntando a esa tienda). Debería aparecer en la portada.

## Notas importantes

- **Confirmación de correo**: por defecto Supabase exige confirmar el correo antes
  de poder iniciar sesión. Puedes desactivar esto temporalmente en
  **Authentication → Providers → Email → "Confirm email"** mientras pruebas.
- **Costo**: la capa gratuita de Supabase incluye 500 MB de base de datos y 1 GB de
  almacenamiento de archivos — suficiente para empezar. Si el proyecto crece,
  Supabase tiene un plan de pago; GitHub Pages siempre es gratis para repositorios
  públicos.
- **Seguridad**: la clave "anon public" es segura para exponer en el frontend —
  Supabase la diseñó para eso. La protección real vive en las políticas de
  Row Level Security definidas en `schema.sql`, que ya limitan qué puede ver o
  modificar cada rol.

## Estructura de archivos

```
/
├── index.html              → catálogo público (vista de cliente)
├── login.html               → inicio de sesión
├── registro.html            → creación de cuenta con selección de rol
├── css/
│   └── estilos.css          → sistema de diseño (colores, tipografía, componentes)
├── js/
│   ├── supabase-config.js   → claves de conexión (edítalo con las tuyas)
│   ├── auth.js               → registro, login, logout, sesión, enrutado por rol
│   └── catalogo.js           → lógica del catálogo público
└── sql/
    └── schema.sql            → base de datos completa + seguridad (RLS)
```

Cuando confirmes que esta fase funciona en tu Supabase y tu GitHub Pages, dime y
seguimos con la Fase 2: panel de vendedor y gestión de productos.
