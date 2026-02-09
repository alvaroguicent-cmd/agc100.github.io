# Reto 8 – Estrategias de seguridad en un SGBD (usuarios, roles, contraseñas, cifrado y acceso)

## 1. Contexto del reto

La tienda online de la Escuela Bojo Bushido ha sufrido incidentes: pedidos borrados y otros pedidos “trolleados” (p. ej., cantidades incoherentes). Se sospecha de un problema de seguridad a nivel de base de datos.

El objetivo del reto es diseñar y aplicar estrategias de seguridad en el sistema gestor de bases de datos, centradas en:
- estructura de usuarios y roles con privilegios mínimos,
- políticas de contraseñas seguras,
- encriptación de datos (en reposo y en tránsito),
- controles de acceso a nivel de objetos y operaciones.

> Nota: La propuesta se basa en PostgreSQL como SGBD de referencia. Los principios aplican a otros SGBD con sintaxis equivalente.

---

## 2. Investigación de mejores prácticas (resumen)

Principios aplicados:
- **Mínimo privilegio (Least Privilege):** cada rol solo con permisos necesarios.
- **Separación de funciones:** administradores ≠ desarrolladores ≠ usuarios de aplicación.
- **Evitar uso de superusuario en aplicaciones:** la app nunca debe conectarse como `postgres`.
- **Auditoría y trazabilidad:** registrar accesos/operaciones relevantes.
- **Cifrado en tránsito:** TLS entre aplicación y BD.
- **Protección de datos sensibles:** cifrado/seudonimización y control de acceso por vistas/funciones.

---

## 3. Estructura de usuarios y roles

### 3.1 Roles propuestos

- **`role_dba`** (administración): gestión del sistema, mantenimiento y auditoría.
- **`role_dev`** (desarrollo): gestión de esquema en entornos no productivos / migraciones controladas.
- **`role_app_rw`** (aplicación lectura/escritura limitada): operaciones CRUD sobre tablas necesarias.
- **`role_app_ro`** (aplicación solo lectura): reporting/consultas.
- **`role_auditor`** (auditoría): acceso de lectura a logs/estadísticas y vistas controladas.

### 3.2 Creación de roles (PostgreSQL)

```sql
-- Roles sin login (agrupan permisos)
CREATE ROLE role_dba;
CREATE ROLE role_dev;
CREATE ROLE role_app_rw;
CREATE ROLE role_app_ro;
CREATE ROLE role_auditor;
```

-- Usuarios con login (se asignan a roles)
```
CREATE USER u_dba WITH LOGIN;
CREATE USER u_dev WITH LOGIN;
CREATE USER u_app WITH LOGIN;
CREATE USER u_reporting WITH LOGIN;
CREATE USER u_auditor WITH LOGIN;
```
-- Asignación de roles
```
GRANT role_dba TO u_dba;
GRANT role_dev TO u_dev;
GRANT role_app_rw TO u_app;
GRANT role_app_ro TO u_reporting;
GRANT role_auditor TO u_auditor;
```

## 3.3 Filosofía de permisos

u_app (cuenta de la web) solo puede operar en el schema de la aplicación y solo en tablas necesarias.

Nadie salvo role_dba debe tener privilegios de administración global.

El desarrollador no debería tener permisos de borrar/alterar en producción salvo mediante despliegues controlados.

## 4. Controles de acceso y permisos (mínimo privilegio)
## 4.1 Preparación: revocar permisos por defecto
-- Importante: por defecto PostgreSQL permite CONNECT a todos en la BD
```
REVOKE ALL ON DATABASE tienda_online FROM PUBLIC;
GRANT CONNECT ON DATABASE tienda_online TO role_dba, role_dev, role_app_rw, role_app_ro, role_auditor;
```
-- Control del schema (ej. "public" o uno específico "app")
```
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO role_app_rw, role_app_ro, role_auditor;
Recomendación práctica: crear un schema app y trabajar ahí para aislar permisos.
CREATE SCHEMA app AUTHORIZATION u_dba;
```
## 4.2 Permisos sobre tablas y secuencias
Ejemplo (suponiendo tablas clientes, productos, pedidos, lineas_pedido):

-- Solo lectura (reporting)
```
GRANT SELECT ON ALL TABLES IN SCHEMA public TO role_app_ro;
```
-- Lectura/escritura limitada para la app
```
GRANT SELECT, INSERT, UPDATE ON public.clientes TO role_app_rw;
GRANT SELECT ON public.productos TO role_app_rw;

GRANT SELECT, INSERT, UPDATE ON public.pedidos TO role_app_rw;
GRANT SELECT, INSERT, UPDATE ON public.lineas_pedido TO role_app_rw;
```
-- Si hay columnas autoincrementales, dar permisos a secuencias
```
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_app_rw;
```
-- Evitar borrados si no son necesarios (ejemplo: NO se concede DELETE)
-- En caso de necesitarlo, concederlo solo sobre tablas concretas y con lógica adicional (soft delete).
## 4.3 Restringir operaciones peligrosas
Evitar DROP, TRUNCATE y DELETE desde cuentas de aplicación.

Usar soft delete (campo deleted_at) si el negocio exige “borrado”.

## 5. Políticas de contraseñas seguras
## 5.1 Requisitos (política propuesta)

Longitud mínima: 14 caracteres

Complejidad: mayúsculas/minúsculas/números/símbolos

No reutilización: al menos 5 contraseñas

Rotación: cada 90 días (según criticidad)

Bloqueo por intentos: a nivel de capa de acceso (proxy/pgbouncer/app) y/o control corporativo

## 5.2 Implementación práctica en PostgreSQL (enfoque realista)
PostgreSQL no trae un “password policy engine” completo como otros SGBD, por lo que se aplica una combinación de:

SCRAM-SHA-256 para almacenar contraseñas.

Reglas operativas (IAM/AD/gestor de secretos) + controles en la capa de app/infra.

Configuración recomendada (parámetros típicos):

password_encryption = 'scram-sha-256'

Deshabilitar cuentas sin necesidad

Usar gestor de secretos (env vars / vault) para credenciales de la app

Ejemplo de creación con expiración:
```
ALTER USER u_app WITH PASSWORD 'Cambia_esta_password_robusta!';
ALTER USER u_app VALID UNTIL '2026-05-01';
En entornos profesionales, lo ideal es evitar contraseñas “humanas” para la app y usar secretos rotados (Vault/Secrets Manager).
```
## 6. Encriptación de datos
## 6.1 Cifrado en tránsito (recomendado: TLS)
Objetivo: que la comunicación App ↔ BD vaya cifrada.

Medidas:

Habilitar TLS en PostgreSQL (ssl = on)

Usar certificados (CA interna o pública)

Forzar conexiones con sslmode=require o superior desde la app

Resultado esperado: evita sniffing/MITM en redes internas o entornos cloud.

## 6.2 Cifrado en reposo (opciones)
Opción A (infraestructura): cifrado a nivel de disco/volumen (LUKS, BitLocker, EBS encryption, etc.).
Ventaja: transparente para la aplicación.

Opción B (base de datos / aplicación): cifrado de campos sensibles.
Ejemplo de datos sensibles:

emails / teléfonos / direcciones,

identificadores personales,

tokens de pago (idealmente no se almacenan; se usan proveedores y tokenización).

En PostgreSQL, una opción habitual es pgcrypto para cifrado de columnas.

Ejemplo conceptual:

-- Requiere extensión
```
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```
-- Ejemplo: cifrar un email (solo como demostración)
-- (La clave NO debe hardcodearse: debe venir de un gestor de secretos)
```
UPDATE clientes
SET email_cifrado = pgp_sym_encrypt(email::text, 'CLAVE_SUPER_SECRETA');
```
-- Ejemplo: descifrar bajo control (solo roles autorizados)
´´´
SELECT pgp_sym_decrypt(email_cifrado, 'CLAVE_SUPER_SECRETA') FROM clientes;
```
En un diseño real: la clave se gestiona fuera de la BD (Vault) y se minimiza el uso de descifrado.
```
## 7. Auditoría y trazabilidad (refuerzo recomendado)
Para investigar borrados y operaciones anómalas, se recomienda:

Activar logging de conexiones: log_connections, log_disconnections

Registrar consultas lentas: log_min_duration_statement

Auditar DDL/DML con extensiones tipo pgaudit (si está disponible)

Además, como medida defensiva:

triggers para registrar cambios en pedidos y lineas_pedido (tabla de auditoría con usuario, fecha, operación, valores clave).


## 8. Conclusiones
La propuesta mejora la seguridad global del SGBD mediante:

separación de roles y privilegios mínimos,

limitación de operaciones destructivas desde cuentas de aplicación,

contraseñas robustas con SCRAM y control de expiración,

cifrado en tránsito (TLS) y estrategia de cifrado en reposo (infra o por columnas),

auditoría para detectar y atribuir acciones maliciosas.

Con estas medidas se reduce drásticamente la probabilidad de borrados no autorizados y se incrementa la capacidad de detección y respuesta ante incidentes.
