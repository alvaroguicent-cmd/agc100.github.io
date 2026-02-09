# Reto 9 – Aplicación web con conexión a base de datos (PostgreSQL)

Este proyecto implementa una aplicación web sencilla (API REST) que se conecta a PostgreSQL para demostrar operaciones básicas de lectura y escritura (CRUD mínimo: CREATE + READ). Cumple los entregables del reto: código fuente y documentación.

---

## 1) Arquitectura

- Servidor: Node.js con Express  
- Base de datos: PostgreSQL (local)  
- Acceso a datos: pg (node-postgres)

Flujo de funcionamiento:
1. El cliente realiza una petición HTTP.
2. Express gestiona la ruta correspondiente.
3. El driver pg ejecuta consultas SQL.
4. PostgreSQL almacena o devuelve los datos.

---

## 2) Tecnologías utilizadas

- Node.js  
- Express  
- PostgreSQL  
- pg (node-postgres)  
- JavaScript  
- npm  

---

## 3) Preparación de PostgreSQL

Creación de la base de datos y la tabla necesarias:

```sql
CREATE DATABASE reto9_db;

\c reto9_db;

CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  edad INTEGER CHECK (edad >= 0),
  fecha_registro TIMESTAMP NOT NULL DEFAULT NOW()
);
```

---

## 4) Estructura del proyecto

```
reto9-postgres/
├── app.js
├── db.js
├── package.json
├── .env
└── README.md
```

---

## 5) Instalación y ejecución

### Requisitos previos
- Node.js instalado
- PostgreSQL en ejecución

### Instalación de dependencias

```bash
npm init -y
npm install express pg dotenv
```

### Configuración de variables de entorno

Archivo `.env`:

```env
PORT=3000
PGHOST=localhost
PGPORT=5432
PGDATABASE=reto9_db
PGUSER=postgres
PGPASSWORD=tu_password
```

### Ejecución de la aplicación

```bash
node app.js
```

La aplicación se inicia en:

http://localhost:3000

---

## 6) Código de la aplicación

### db.js – Conexión a PostgreSQL

```js
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.PGHOST,
  port: Number(process.env.PGPORT || 5432),
  database: process.env.PGDATABASE,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
});

pool.query('SELECT 1')
  .then(() => console.log('Conectado a PostgreSQL'))
  .catch(err => console.error('Error de conexión', err.message));

module.exports = pool;
```

### app.js – API REST

```js
require('dotenv').config();
const express = require('express');
const pool = require('./db');

const app = express();
app.use(express.json());

app.post('/usuarios', async (req, res) => {
  try {
    const { nombre, email, edad } = req.body;

    if (!nombre || !email) {
      return res.status(400).json({ error: 'nombre y email son obligatorios' });
    }

    const result = await pool.query(
      `INSERT INTO usuarios (nombre, email, edad)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [nombre, email, edad ?? null]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'email duplicado' });
    }
    res.status(500).json({ error: 'error interno', detalle: err.message });
  }
});

app.get('/usuarios', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM usuarios ORDER BY id DESC'
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'error interno', detalle: err.message });
  }
});

app.get('/usuarios/:id', async (req, res) => {
  try {
    const id = Number(req.params.id);
    const result = await pool.query(
      'SELECT * FROM usuarios WHERE id = $1',
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'usuario no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'error interno', detalle: err.message });
  }
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => {
  console.log(`Servidor iniciado en http://localhost:${port}`);
});
```

---

## 7) Uso de la aplicación

### Crear usuario

Endpoint:  
POST /usuarios

Ejemplo de cuerpo JSON:

```json
{
  "nombre": "Juan Pérez",
  "email": "juan@example.com",
  "edad": 30
}
```

### Listar usuarios

Endpoint:  
GET /usuarios

### Obtener usuario por ID

Endpoint:  
GET /usuarios/:id

---

## 8) Seguridad y buenas prácticas

- Uso de consultas SQL parametrizadas para evitar inyecciones.
- Credenciales almacenadas en variables de entorno.
- Validaciones básicas de entrada.

---

## 9) Entregables

- Código fuente de la aplicación.
- Documentación con arquitectura, tecnologías y guía de uso.
- Instrucciones de configuración de la base de datos.

---

## 10) Conclusión

La aplicación demuestra correctamente la conexión entre una aplicación web y una base de datos PostgreSQL, permitiendo operaciones básicas de lectura y escritura de forma segura y estructurada.
