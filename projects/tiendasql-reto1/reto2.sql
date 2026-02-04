select c.nombre AS categoria,
  sum(dp.cantidad*dp.precio_unitario) as total_ventas
  from categorias c
JOIN productos p
  ON p.categoria_id = c.categoria_id
JOIN detalles_pedido dp
  ON dp.producto_id = p.producto_id
GROUP BY c.nombre
ORDER BY total_ventas DESC;

SELECT
  c.cliente_id,
  c.nombre,
  AVG(t.total_pedido) AS gasto_promedio
FROM clientes c
JOIN (
  SELECT
    p.cliente_id,
    p.pedido_id,
    SUM(dp.cantidad * dp.precio_unitario) AS total_pedido
  FROM pedidos p
  JOIN detalles_pedido dp
    ON dp.pedido_id = p.pedido_id
  GROUP BY p.cliente_id, p.pedido_id
) t
  ON t.cliente_id = c.cliente_id
GROUP BY c.cliente_id, c.nombre
ORDER BY gasto_promedio DESC;


SELECT pr.producto_id, pr.nombre as nombre_producto
 sum(dp.cantidad) as unidades_vendidas

FROM productos pr

JOIN detalles_pedido dp
  ON dp.producto_id = pr.producto_id
GROUP BY pr.producto_id, p.nombre
ORDER BY unidades_vendidas DESC;

SELECT c.cliente_id, c.nombre, c.apellido
FROM clientes c
LEFT JOIN pedidos p
  ON p.cliente_id = c.cliente_id
WHERE p.pedido_id IS NULL
ORDER BY c.cliente_id;

  