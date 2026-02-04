CREATE TABLE iti_fundae_sql_server.clientes (
  cliente_id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL
);

CREATE TABLE iti_fundae_sql_server.pedidos (
  pedido_id SERIAL PRIMARY KEY,
  cliente_id INT NOT NULL,
  fecha DATE NOT NULL,
  CONSTRAINT fk_pedidos_clientes
    FOREIGN KEY (cliente_id)
    REFERENCES iti_fundae_sql_server.clientes(cliente_id)
);

CREATE TABLE iti_fundae_sql_server.productos (
  producto_id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  precio NUMERIC(10,2) NOT NULL CHECK (precio >= 0)
);

CREATE TABLE iti_fundae_sql_server.detalles (
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL CHECK (cantidad > 0),
  precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),

  CONSTRAINT pk_detalles PRIMARY KEY (pedido_id, producto_id),

  CONSTRAINT fk_detalles_pedido
    FOREIGN KEY (pedido_id)
    REFERENCES iti_fundae_sql_server.pedidos(pedido_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_detalles_producto
    FOREIGN KEY (producto_id)
    REFERENCES iti_fundae_sql_server.productos(producto_id)
);

SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRAN;

--SECCIÓN 1: INSERCIÓN DE DATOS (INSERT) - DATOS DE EJEMPLO


    -- Limpieza opcional (para poder re-ejecutar el script sin duplicados)
    -- Si NO quieres borrar, comenta estas 4 líneas.
    DELETE FROM dbo.detalles;
    DELETE FROM dbo.pedidos;
    DELETE FROM dbo.productos;
    DELETE FROM dbo.clientes;

    -- CLIENTES
    INSERT INTO dbo.clientes (nombre)
    VALUES
      ('Ana Pérez'),
      ('Luis Gómez'),
      ('Marta Ruiz');

    -- PRODUCTOS
    INSERT INTO dbo.productos (nombre, precio)
    VALUES
      ('Cuaderno A4', 2.50),
      ('Bolígrafo azul', 0.90),
      ('Mochila', 24.99),
      ('Regla 30cm', 1.20);

    -- PEDIDOS (usaremos IDs reales de clientes insertados)
    INSERT INTO dbo.pedidos (cliente_id, fecha)
    VALUES
      ((SELECT cliente_id FROM dbo.clientes WHERE nombre = 'Ana Pérez'),  '2026-02-01'),
      ((SELECT cliente_id FROM dbo.clientes WHERE nombre = 'Luis Gómez'), '2026-02-02'),
      ((SELECT cliente_id FROM dbo.clientes WHERE nombre = 'Ana Pérez'),  '2026-02-03');

    -- DETALLES (líneas de pedido)
    -- Nota: se asume PK (pedido_id, producto_id) => no repetimos mismo producto en el mismo pedido
    DECLARE @p1 INT = (SELECT MIN(pedido_id) FROM dbo.pedidos WHERE fecha = '2026-02-01');
    DECLARE @p2 INT = (SELECT MIN(pedido_id) FROM dbo.pedidos WHERE fecha = '2026-02-02');
    DECLARE @p3 INT = (SELECT MIN(pedido_id) FROM dbo.pedidos WHERE fecha = '2026-02-03');

    DECLARE @cuaderno INT = (SELECT producto_id FROM dbo.productos WHERE nombre = 'Cuaderno A4');
    DECLARE @boli     INT = (SELECT producto_id FROM dbo.productos WHERE nombre = 'Bolígrafo azul');
    DECLARE @mochila  INT = (SELECT producto_id FROM dbo.productos WHERE nombre = 'Mochila');
    DECLARE @regla    INT = (SELECT producto_id FROM dbo.productos WHERE nombre = 'Regla 30cm');

    INSERT INTO dbo.detalles (pedido_id, producto_id, cantidad, precio_unitario)
    VALUES
      (@p1, @cuaderno, 2, 2.50),
      (@p1, @boli,     5, 0.90),
      (@p2, @mochila,  1, 24.99),
      (@p2, @regla,    2, 1.20),
      (@p3, @cuaderno, 1, 2.50),
      (@p3, @regla,    1, 1.20);

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    THROW;
END CATCH;

PRINT 'Inserciones completadas.';

--SECCIÓN 2: CONSULTAS BÁSICAS (SELECT + WHERE)

-- 2.1 Listar todos los productos disponibles
SELECT producto_id, nombre, precio
FROM dbo.productos
ORDER BY producto_id;

-- 2.2 Mostrar detalles de los clientes (todos o filtrado)
SELECT cliente_id, nombre
FROM dbo.clientes
ORDER BY cliente_id;

-- 2.3 Ver pedidos realizados en una fecha específica (WHERE)
DECLARE @fecha_buscada DATE = '2026-02-02';

SELECT p.pedido_id, p.fecha, c.cliente_id, c.nombre AS cliente
FROM dbo.pedidos p
JOIN dbo.clientes c ON c.cliente_id = p.cliente_id
WHERE p.fecha = @fecha_buscada
ORDER BY p.pedido_id;

-- 2.4 Ver el detalle (líneas) de pedidos en un rango de fechas (WHERE)

SELECT p.pedido_id, p.fecha, pr.nombre AS producto, d.cantidad, d.precio_unitario
FROM dbo.detalles d
JOIN dbo.pedidos p   ON p.pedido_id = d.pedido_id
JOIN dbo.productos pr ON pr.producto_id = d.producto_id
WHERE p.fecha BETWEEN '2026-02-01' AND '2026-02-03'
ORDER BY p.fecha, p.pedido_id, pr.nombre;

--SECCIÓN 3: FUNCIÓN (T-SQL)

IF OBJECT_ID('dbo.fn_veces_pedido_producto', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_veces_pedido_producto;
GO

CREATE FUNCTION dbo.fn_veces_pedido_producto (@producto_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @veces INT;

    SELECT @veces = COUNT(*)
    FROM dbo.detalles
    WHERE producto_id = @producto_id;

    RETURN ISNULL(@veces, 0);
END;
GO

-- 3.1 Usar la función en una consulta SELECT 

SELECT
    pr.producto_id,
    pr.nombre,
    pr.precio,
    dbo.fn_veces_pedido_producto(pr.producto_id) AS veces_pedido
FROM dbo.productos pr
ORDER BY veces_pedido DESC, pr.nombre;

-- Extra útil (opcional): unidades totales vendidas (sin función)
SELECT
    pr.producto_id,
    pr.nombre,
    SUM(d.cantidad) AS unidades_totales
FROM dbo.productos pr
LEFT JOIN dbo.detalles d ON d.producto_id = pr.producto_id
GROUP BY pr.producto_id, pr.nombre
ORDER BY unidades_totales DESC, pr.nombre;