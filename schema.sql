-- ============================================================
-- ESQUEMA DE BASE DE DATOS — Plataforma Marketplace Cuba
-- Motor: PostgreSQL (Supabase)
-- Cómo usarlo: Supabase > SQL Editor > pega este archivo > Run
-- ============================================================

-- Extensión necesaria para generar UUIDs
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- ENUM: roles y estados usados en varias tablas
-- ------------------------------------------------------------
create type rol_usuario as enum ('cliente', 'vendedor', 'proveedor_servicio', 'repartidor', 'admin');
create type estado_cuenta as enum ('activo', 'pendiente_verificacion', 'suspendido');
create type tipo_producto as enum ('fisico', 'digital', 'servicio_domicilio');
create type estado_pedido as enum ('pendiente', 'pagado', 'en_camino', 'completado', 'disputa', 'cancelado');
create type estado_disputa as enum ('abierta', 'en_revision', 'resuelta');

-- ------------------------------------------------------------
-- PERFILES
-- Extiende la tabla interna auth.users que ya crea Supabase.
-- Un usuario se registra con Supabase Auth (email + password)
-- y aquí guardamos sus datos de negocio.
-- ------------------------------------------------------------
create table perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  cedula text,
  telefono text,
  provincia text,
  municipio text,
  rol rol_usuario not null default 'cliente',
  foto_id_url text,
  estado estado_cuenta not null default 'pendiente_verificacion',
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- CUENTAS BANCARIAS (para recibir pagos / retiros)
-- ------------------------------------------------------------
create table cuentas_bancarias (
  id uuid primary key default gen_random_uuid(),
  perfil_id uuid not null references perfiles(id) on delete cascade,
  banco text not null,
  numero_cuenta text not null,
  tipo text,
  principal boolean not null default false,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- TIENDAS / PERFILES DE VENDEDOR O PRESTADOR DE SERVICIO
-- ------------------------------------------------------------
create table tiendas (
  id uuid primary key default gen_random_uuid(),
  perfil_id uuid not null references perfiles(id) on delete cascade,
  nombre text not null,
  descripcion text,
  foto_url text,
  categoria text,
  provincia text,
  municipio text,
  valoracion_promedio numeric(2,1) default 0,
  total_ventas integer default 0,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- PRODUCTOS Y SERVICIOS
-- ------------------------------------------------------------
create table productos_servicios (
  id uuid primary key default gen_random_uuid(),
  tienda_id uuid not null references tiendas(id) on delete cascade,
  tipo tipo_producto not null,
  titulo text not null,
  descripcion text,
  precio numeric(12,2) not null,
  moneda text not null default 'CUP',
  stock integer default 1,
  archivo_url text,
  imagen_url text,
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- PEDIDOS
-- ------------------------------------------------------------
create table pedidos (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references perfiles(id),
  tienda_id uuid not null references tiendas(id),
  estado estado_pedido not null default 'pendiente',
  total numeric(12,2) not null,
  moneda text not null default 'CUP',
  metodo_pago text,
  pin_entrega text,
  direccion_entrega text,
  created_at timestamptz not null default now()
);

create table pedido_items (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references pedidos(id) on delete cascade,
  producto_id uuid not null references productos_servicios(id),
  cantidad integer not null default 1,
  precio_unitario numeric(12,2) not null
);

-- ------------------------------------------------------------
-- SERVICIOS A DOMICILIO (entregas estilo Uber/Rappi)
-- ------------------------------------------------------------
create table servicios_domicilio (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references pedidos(id) on delete cascade,
  repartidor_id uuid references perfiles(id),
  direccion_origen text,
  direccion_destino text,
  distancia_km numeric(6,2),
  tarifa_envio numeric(10,2),
  foto_carga_url text,
  foto_entrega_url text,
  estado estado_pedido not null default 'pendiente',
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- RESEÑAS Y VALORACIONES
-- ------------------------------------------------------------
create table resenas (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references pedidos(id),
  evaluador_id uuid not null references perfiles(id),
  evaluado_id uuid not null references perfiles(id),
  calificacion smallint not null check (calificacion between 1 and 5),
  comentario text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- DISPUTAS Y REPORTES
-- ------------------------------------------------------------
create table disputas (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references pedidos(id),
  demandante_id uuid not null references perfiles(id),
  motivo text not null,
  evidencias_url text,
  estado estado_disputa not null default 'abierta',
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- COMISIONES / FINANZAS DE LA PLATAFORMA
-- ------------------------------------------------------------
create table comisiones (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references pedidos(id),
  monto_comision numeric(12,2) not null,
  porcentaje numeric(4,2) not null,
  created_at timestamptz not null default now()
);

-- ============================================================
-- FUNCIÓN + TRIGGER: crear fila en "perfiles" automáticamente
-- cuando alguien se registra vía Supabase Auth.
-- ============================================================
create or replace function public.manejar_nuevo_usuario()
returns trigger as $$
begin
  insert into public.perfiles (id, nombre, rol, telefono, cedula)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nombre', 'Usuario nuevo'),
    coalesce((new.raw_user_meta_data->>'rol')::rol_usuario, 'cliente'),
    new.raw_user_meta_data->>'telefono',
    new.raw_user_meta_data->>'cedula'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute procedure public.manejar_nuevo_usuario();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Todo bloqueado por defecto; se abre solo lo necesario.
-- ============================================================
alter table perfiles enable row level security;
alter table cuentas_bancarias enable row level security;
alter table tiendas enable row level security;
alter table productos_servicios enable row level security;
alter table pedidos enable row level security;
alter table pedido_items enable row level security;
alter table servicios_domicilio enable row level security;
alter table resenas enable row level security;
alter table disputas enable row level security;
alter table comisiones enable row level security;

-- función auxiliar: ¿el usuario actual es admin?
create or replace function public.es_admin()
returns boolean as $$
  select exists (
    select 1 from perfiles where id = auth.uid() and rol = 'admin'
  );
$$ language sql security definer stable;

-- PERFILES: cada quien ve y edita el suyo; admin ve todos
create policy "ver perfil propio o admin" on perfiles
  for select using (auth.uid() = id or public.es_admin());
create policy "editar perfil propio o admin" on perfiles
  for update using (auth.uid() = id or public.es_admin());

-- CUENTAS BANCARIAS: solo el dueño
create policy "gestionar cuentas propias" on cuentas_bancarias
  for all using (perfil_id = auth.uid());

-- TIENDAS: lectura pública, escritura solo del dueño
create policy "ver tiendas" on tiendas
  for select using (true);
create policy "crear tienda propia" on tiendas
  for insert with check (perfil_id = auth.uid());
create policy "editar tienda propia" on tiendas
  for update using (perfil_id = auth.uid());

-- PRODUCTOS/SERVICIOS: lectura pública si está activo, escritura del dueño de la tienda
create policy "ver productos activos" on productos_servicios
  for select using (activo = true or tienda_id in (select id from tiendas where perfil_id = auth.uid()));
create policy "crear productos en tienda propia" on productos_servicios
  for insert with check (tienda_id in (select id from tiendas where perfil_id = auth.uid()));
create policy "editar productos propios" on productos_servicios
  for update using (tienda_id in (select id from tiendas where perfil_id = auth.uid()));

-- PEDIDOS: cliente, vendedor involucrado o admin
create policy "ver pedidos propios" on pedidos
  for select using (
    cliente_id = auth.uid()
    or tienda_id in (select id from tiendas where perfil_id = auth.uid())
    or public.es_admin()
  );
create policy "crear pedido como cliente" on pedidos
  for insert with check (cliente_id = auth.uid());
create policy "actualizar pedido si involucrado" on pedidos
  for update using (
    cliente_id = auth.uid()
    or tienda_id in (select id from tiendas where perfil_id = auth.uid())
    or public.es_admin()
  );

-- ITEMS DE PEDIDO: heredan visibilidad del pedido
create policy "ver items de mis pedidos" on pedido_items
  for select using (
    pedido_id in (
      select id from pedidos where cliente_id = auth.uid()
      or tienda_id in (select id from tiendas where perfil_id = auth.uid())
    ) or public.es_admin()
  );
create policy "crear items en mis pedidos" on pedido_items
  for insert with check (
    pedido_id in (select id from pedidos where cliente_id = auth.uid())
  );

-- SERVICIOS A DOMICILIO: repartidor asignado, dueño del pedido o admin
create policy "ver mis envios" on servicios_domicilio
  for select using (
    repartidor_id = auth.uid()
    or pedido_id in (select id from pedidos where cliente_id = auth.uid())
    or public.es_admin()
  );
create policy "repartidores toman envios sin asignar" on servicios_domicilio
  for update using (repartidor_id = auth.uid() or repartidor_id is null or public.es_admin());

-- RESEÑAS: lectura pública, solo el evaluador crea la suya
create policy "ver resenas" on resenas
  for select using (true);
create policy "crear resena propia" on resenas
  for insert with check (evaluador_id = auth.uid());

-- DISPUTAS: el demandante, la contraparte del pedido, o admin
create policy "ver disputas propias o admin" on disputas
  for select using (demandante_id = auth.uid() or public.es_admin());
create policy "crear disputa propia" on disputas
  for insert with check (demandante_id = auth.uid());
create policy "admin resuelve disputas" on disputas
  for update using (public.es_admin());

-- COMISIONES: solo admin
create policy "solo admin ve comisiones" on comisiones
  for select using (public.es_admin());
