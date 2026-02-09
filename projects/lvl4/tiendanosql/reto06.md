# Reto: Modelado de datos en un SGBD NoSQL

## Elección del sistema gestor de bases de datos NoSQL

Para el desarrollo de una tienda online se ha optado por **MongoDB** como sistema gestor de bases de datos NoSQL principal. Se trata de una base de datos orientada a documentos que permite almacenar la información en formato JSON/BSON, facilitando un modelado flexible y adaptado a la naturaleza cambiante de los datos propios de una plataforma de comercio electrónico.

La elección de MongoDB responde a la necesidad de gestionar información heterogénea (productos con múltiples atributos, clientes con distintas direcciones, pedidos con líneas variables), garantizando al mismo tiempo un buen rendimiento y escalabilidad horizontal.

## Justificación de la elección

En una tienda online, los datos no siguen siempre una estructura rígida. Los productos pueden tener diferentes características según su categoría, los pedidos contienen un número variable de líneas y los clientes pueden modificar sus datos con frecuencia. MongoDB permite adaptar el esquema de datos sin necesidad de redefinir tablas o relaciones complejas, lo que resulta especialmente útil en entornos donde el modelo de negocio cambia o evoluciona.

Además, MongoDB está diseñada para escalar horizontalmente mediante **sharding**, lo que la hace adecuada para aplicaciones web con crecimiento progresivo del número de usuarios y transacciones. Su integración con aplicaciones web modernas y APIs REST es sencilla, reduciendo la complejidad del desarrollo.

## Modelo de datos propuesto

El sistema se estructura en tres colecciones principales: productos, clientes y pedidos.

### Colección "products"

Almacena la información de los productos disponibles en la tienda. Cada documento representa un producto individual e incluye: identificador, nombre, precio, stock, categorías y atributos específicos como talla o color. Esta estructura permite que productos de distintas categorías tengan campos diferentes sin afectar al resto del sistema.

### Colección "customers"

Contiene los datos de los clientes, incluyendo correo electrónico, nombre y un conjunto de direcciones asociadas. Las direcciones se almacenan como documentos embebidos, ya que forman parte directa del cliente y se consultan habitualmente junto a él.

### Colección "orders"

Representa los pedidos realizados. Cada pedido incluye una referencia al cliente, el estado del pedido, la información del pago y las líneas del pedido embebidas. Las líneas del pedido contienen una copia del nombre y precio del producto en el momento de la compra, garantizando la coherencia histórica aunque el producto cambie posteriormente.

Este enfoque permite que cada pedido sea un documento autónomo, optimizando las consultas habituales como la visualización del historial de pedidos de un cliente.

## Gestión de relaciones entre datos

MongoDB no utiliza relaciones clásicas mediante claves foráneas como los sistemas relacionales. En su lugar, se emplea una combinación de referencias y documentos embebidos.

En este modelo, los pedidos incluyen una referencia al cliente mediante su identificador, mientras que las líneas del pedido se almacenan embebidas dentro del propio documento del pedido. Esta decisión reduce la necesidad de realizar múltiples consultas y mejora el rendimiento en operaciones frecuentes, como la consulta de un pedido completo.

## Uso complementario de Redis

Aunque MongoDB actúa como base de datos principal y fuente de verdad del sistema, se propone el uso de Redis como componente auxiliar para la gestión de datos temporales y de alto rendimiento.

Redis se emplea para almacenar el carrito de la compra de los usuarios, gestionar estados temporales del proceso de pago, implementar mecanismos de idempotencia que eviten cobros duplicados y cachear información de productos consultados con frecuencia. Estos datos tienen una vida útil limitada y no requieren persistencia a largo plazo, por lo que no se almacenan en MongoDB.

De este modo, Redis mejora el rendimiento y la experiencia de usuario sin sustituir a la base de datos principal.

## Ventajas y desafíos frente a un sistema relacional

El uso de MongoDB presenta claras ventajas frente a un sistema relacional tradicional, como la flexibilidad del esquema, la facilidad para modelar estructuras complejas y la escalabilidad horizontal. Estas características hacen que MongoDB sea especialmente adecuada para aplicaciones web modernas y dinámicas.

No obstante, también existen desafíos. La ausencia de joins complejos y de transacciones multi-documento tan robustas como en los sistemas relacionales obliga a diseñar cuidadosamente el modelo de datos. Además, se requiere mayor responsabilidad por parte del desarrollador para mantener la coherencia de la información.

A pesar de ello, para una tienda online con requisitos de flexibilidad y crecimiento, MongoDB constituye una solución adecuada y eficiente.

