CREATE TABLE clientes (
  cliente_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre      varchar(80)  NOT NULL,
  apellido    varchar(80)  NOT NULL,
  municipio   varchar(100),
  email       varchar(255) NOT NULL UNIQUE
);

CREATE TABLE productos (
  producto_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre        varchar(120) NOT NULL,
  descripcion   varchar(255),
  precio        numeric(10,2) NOT NULL,
  stock         integer NOT NULL DEFAULT 0,

  CONSTRAINT chk_producto_precio
    CHECK (precio >= 0),

  CONSTRAINT chk_producto_stock
    CHECK (stock >= 0),

  CONSTRAINT uq_productos_nombre
    UNIQUE (nombre)
);

CREATE TABLE pedidos (
  pedido_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cliente_id     integer NOT NULL,
  fecha_pedido   timestamp NOT NULL DEFAULT now(),
  estado         varchar(20) NOT NULL DEFAULT 'PENDIENTE',
  total          numeric(10,2) NOT NULL DEFAULT 0,
  metodo_pago    varchar(50),
  metodo_envio   varchar(50),

  CONSTRAINT fk_pedidos_cliente
    FOREIGN KEY (cliente_id)
    REFERENCES clientes (cliente_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

  CONSTRAINT chk_pedidos_total
    CHECK (total >= 0),

  CONSTRAINT chk_pedidos_estado
    CHECK (estado IN ('PENDIENTE','PAGADO','ENVIADO','CANCELADO'))
);

CREATE TABLE detalles_pedido (
  detalle_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pedido_id       integer NOT NULL,
  producto_id     integer NOT NULL,
  cantidad        integer NOT NULL,
  precio_unitario numeric(10,2) NOT NULL,

  CONSTRAINT fk_detalle_pedido
    FOREIGN KEY (pedido_id)
    REFERENCES pedidos (pedido_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT fk_detalle_producto
    FOREIGN KEY (producto_id)
    REFERENCES productos (producto_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

  CONSTRAINT chk_detalle_cantidad
    CHECK (cantidad > 0),

  CONSTRAINT chk_detalle_precio
    CHECK (precio_unitario >= 0),

  CONSTRAINT uq_detalle_pedido_producto
    UNIQUE (pedido_id, producto_id)
);
