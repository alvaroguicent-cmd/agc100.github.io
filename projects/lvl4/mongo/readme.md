# Reto MongoDB – Importación y exportación de datos

Este proyecto corresponde a un reto práctico de MongoDB cuyo objetivo es importar un archivo JSON en una base de datos, realizar varias consultas sobre la colección resultante y exportar a un nuevo archivo JSON los resultados de una consulta concreta.

El trabajo se ha realizado íntegramente mediante línea de comandos y la shell de MongoDB, sin usar Compass.

---

## Estructura del repositorio

├── libros.json
├── libros_fantasia.json
└── README.md


- `libros.json`: archivo original proporcionado en el reto.
- `libros_fantasia.json`: archivo exportado con los libros de género Fantasía (entregable final).
- `README.md`: documentación del proceso seguido.

---

## 1 Importación de datos

Se importa el archivo `libros.json` en una base de datos llamada `biblioteca` y una colección llamada `libros` usando el comando `mongoimport`:

mongoimport --db biblioteca --collection libros --file libros.json --jsonArray

##Consultas realizadas

Una vez importados los datos, se accede a la shell de MongoDB (mongosh) y se selecciona la base de datos:

use biblioteca

db.libros.find({ anioPublicacion: { $lt: 1950 } })

Libros del género Fantasía
db.libros.find({ genero: "Fantasia" })


Devuelve todos los libros clasificados como Fantasía.

Libros escritos por J.R.R. Tolkien
db.libros.find({ autores: "J.R.R. Tolkien" })


Busca los documentos cuyo array autores contiene el valor "J.R.R. Tolkien".

Número de libros por género
db.libros.aggregate([
  {
    $group: {
      _id: "$genero",
      total: { $sum: 1 }
    }
  }
])


Agrupa los libros por género y cuenta cuántos pertenecen a cada uno.

3 Exportación de datos

Como paso final, se exportan a un nuevo archivo JSON todos los libros de género Fantasía utilizando mongoexport con una consulta (--query):

mongoexport --db biblioteca --collection libros --query '{"genero":"Fantasia"}' --out libros_fantasia.json


El archivo generado (libros_fantasia.json) contiene únicamente los documentos que cumplen la condición indicada y constituye el entregable final del reto.
Filtra los libros cuyo año de publicación es anterior a 1950.
