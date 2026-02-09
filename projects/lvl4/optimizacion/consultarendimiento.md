# Reto 7 – Optimización de Rendimiento en Base de Datos

## 1. Contexto del reto

La Escuela Bojo Bushido dispone de una tienda online utilizada por sus alumnos para realizar pedidos de material de estudio y entrenamiento. En determinados momentos, el sistema presenta problemas de rendimiento, errores en las consultas y pérdida de pedidos.  
El objetivo de este reto es analizar el rendimiento de la base de datos, identificar los problemas existentes y proponer mejoras mediante la optimización de consultas, la creación de índices y la definición de una estrategia de particionamiento.

---

## 2. Análisis inicial de rendimiento

Se han identificado como consultas críticas aquellas que se ejecutan con mayor frecuencia y que afectan directamente a la experiencia del usuario. Entre ellas destacan:

- Consultas de pedidos filtradas por cliente.
- Consultas de pedidos por rangos de fechas.
- Consultas agregadas para obtener estadísticas de ventas.
- Consultas que realizan múltiples `JOIN` entre tablas de pedidos y líneas de pedido.

Estas consultas presentan tiempos de respuesta elevados debido al volumen de datos y a la ausencia de mecanismos de optimización adecuados, lo que provoca un consumo excesivo de recursos y bloqueos puntuales del sistema.

---

## 3. Identificación de problemas de rendimiento

Tras el análisis, se han detectado los siguientes problemas principales:

- Ausencia de índices en columnas utilizadas frecuentemente en cláusulas `WHERE` y `JOIN`.
- Uso de funciones sobre columnas en filtros, impidiendo el uso eficiente de índices.
- Recuperación de más columnas de las necesarias mediante consultas `SELECT *`.
- Crecimiento progresivo de tablas como `pedidos`, sin una estrategia de particionamiento definida.

Estos factores obligan al motor de base de datos a realizar escaneos completos de tablas, incrementando significativamente el tiempo de ejecución de las consultas.

---

## 4. Optimización de consultas

Se han propuesto modificaciones en las consultas para mejorar su eficiencia.

### Ejemplo de consulta ineficiente

```sql
SELECT *
FROM pedidos
WHERE YEAR(fecha_pedido) = 2024;
```

### Consulta optimizada

```sql
SELECT id, cliente_id, fecha_pedido, total
FROM pedidos
WHERE fecha_pedido BETWEEN '2024-01-01' AND '2024-12-31';
```

Con esta modificación se evita el uso de funciones sobre la columna y se limitan las columnas recuperadas, permitiendo al optimizador aprovechar los índices disponibles y reduciendo el volumen de datos procesados.

## 5. Implementación de índices

Para mejorar el rendimiento de las consultas más frecuentes, se propone la creación de los siguientes índices:

CREATE INDEX idx_pedidos_cliente
ON pedidos(cliente_id);

CREATE INDEX idx_pedidos_fecha
ON pedidos(fecha_pedido);

CREATE INDEX idx_lineas_pedido_pedido
ON lineas_pedido(pedido_id);


Estos índices permiten acelerar las búsquedas filtradas por cliente y fecha, así como las operaciones JOIN entre pedidos y líneas de pedido.

Tras la implementación de los índices, se espera una reducción significativa del tiempo de respuesta de las consultas críticas, a cambio de un ligero aumento del coste en las operaciones de inserción y actualización, considerado asumible en este contexto.

## 6. Estrategia de particionamiento

Dado el crecimiento continuo de la tabla pedidos, se propone una estrategia de particionamiento por rango basada en la columna fecha_pedido, utilizando intervalos anuales.

Esta estrategia permitiría:

Reducir el volumen de datos analizados en consultas por rangos de fechas.

Mejorar el rendimiento de consultas históricas.

Facilitar tareas de mantenimiento, archivado y limpieza de datos antiguos.

El particionamiento se considera especialmente adecuado para tablas con gran volumen de datos y consultas predominantemente temporales.

## 7. Conclusiones

Mediante el análisis del rendimiento, la optimización de consultas, la creación de índices adecuados y la definición de una estrategia de particionamiento, es posible mejorar significativamente la eficiencia de la base de datos de la tienda online.
Estas medidas contribuyen a reducir los tiempos de respuesta, minimizar el consumo de recursos y aumentar la fiabilidad del sistema, evitando la pérdida de pedidos y mejorando la experiencia de los usuarios.
