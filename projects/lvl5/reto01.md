---
layout: default
title: "Reto 1 – Alta disponibilidad, replicación y clúster"
description: "Diseño de un esquema básico de replicación de datos y clúster para una aplicación empresarial (Federación Samurái)."
---

# Reto 1 – Alta disponibilidad, replicación y clúster

Este reto consiste en diseñar un esquema básico de replicación y una propuesta de clúster para una base de datos que soporta una aplicación web y móvil orientada a localizar samuráis, contratar sus servicios y consultar habilidades. Se busca un enfoque empresarial con alta disponibilidad, replicación y tolerancia a fallos.

---

## 1. Introducción a la alta disponibilidad

La **alta disponibilidad (High Availability)** es la capacidad de un sistema de bases de datos para permanecer operativo el mayor tiempo posible, minimizando interrupciones. En aplicaciones empresariales es crítica porque una caída puede suponer pérdida de ventas, mala experiencia de usuario e incluso pérdida de información sensible.

En un escenario como el de la Federación Samurái, la disponibilidad es clave porque los usuarios pueden estar contratando servicios o consultando perfiles en cualquier momento, especialmente durante eventos o picos de demanda.

La **replicación** consiste en mantener copias de los datos en uno o más servidores adicionales (réplicas). Sus objetivos principales son:
- **Redundancia** ante fallos del servidor principal.
- **Mejor rendimiento en lectura** al repartir consultas.
- **Recuperación** más sencilla ante incidencias.

Un **clúster** es un conjunto de servidores que trabajan coordinados para ofrecer un servicio conjunto con mayor disponibilidad, tolerancia a fallos y escalabilidad. Un clúster puede incluir balanceadores, monitorización y mecanismos automáticos de failover.

---

## 2. Diseño de la replicación

### Modelo elegido: Maestro–Esclavo (Primary–Replica)

Se propone un modelo **Maestro–Réplica**, donde:
- El **MASTER** recibe las escrituras (altas, cambios de disponibilidad, contrataciones, etc.).
- Una o varias **RÉPLICAS** reciben los cambios desde el master y se usan principalmente para lecturas (búsquedas y consultas de perfiles).

Este modelo es adecuado cuando el patrón de uso es: **muchas lecturas y menos escrituras**, algo típico de una app de consulta de perfiles y contratación.

### Flujo de datos y sincronización

1. Las operaciones de **escritura** se realizan en el nodo MASTER.
2. El MASTER registra cambios (logs de transacciones).
3. Las réplicas reciben los cambios y se sincronizan con el MASTER.
4. Las operaciones de **lectura** se reparten entre réplicas para mejorar el rendimiento.

Se puede usar replicación **asíncrona** para priorizar rendimiento, asumiendo que una pequeña latencia de sincronización es aceptable para la mayoría de consultas.

### Diagrama (ASCII)

```text
                Aplicación Web/Móvil
                        |
                 ┌─────────────┐
                 │   MASTER    │
                 │  (Escritura)│
                 └──────┬──────┘
                        |
        Replicación síncrona/asíncrona
                        |
        ┌───────────────┼───────────────┐
        │                               │
 ┌─────────────┐                 ┌─────────────┐
 │  REPLICA 1  │                 │  REPLICA 2  │
 │  (Lectura)  │                 │  (Lectura)  │
 └─────────────┘                 └─────────────┘
```
## 3. Implementación de clústeres
Objetivo del clúster

El clúster mejora la disponibilidad mediante:

Balanceo de carga (reparto de tráfico).

Failover automático (si el master cae, se promueve una réplica).

Monitorización (detección rápida de fallos).

Recuperación ante desastres (posible despliegue multi-región).

Manejo de fallas (failover)

Escenario: cae el MASTER.

El sistema de monitorización detecta el fallo.

Se promueve una réplica como nuevo MASTER.

El balanceador redirige el tráfico al nuevo MASTER.

La aplicación continúa operando con mínima interrupción.

Diagrama (ASCII)

```
                   Usuarios
                       |
                ┌─────────────┐
                │ LoadBalancer│
                └──────┬──────┘
                       |
        ┌──────────────┼──────────────┐
        │                              │
   ┌─────────────┐                ┌─────────────┐
   │  Nodo 1     │                │  Nodo 2     │
   │ (Master)    │                │ (Replica)   │
   └──────┬──────┘                └──────┬──────┘
          │                               │
          └───────────── Monitor ──────────┘

```

