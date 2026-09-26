---
name: delegar
description: Convierte lo acordado en la conversación en una especificación cerrada y la entrega a los agentes de trabajo (implementador en Sonnet, verificador en Haiku) en lugar de ejecutarla con el modelo principal. Usar cuando el usuario diga "ejecútalo", "hazlo", "impleméntalo", "manos a la obra" o cuando termine una discusión de diseño y toque escribir código.
---

# Delegar

El modelo principal diseña; los agentes ejecutan. Este skill es el puente.

## 1. Especificación (escríbela tú, corta)

Antes de lanzar nada, redacta la especificación con este formato exacto. Máximo 25 líneas:

```
OBJETIVO: <una frase>
ARCHIVOS: <rutas que se crean o modifican>
CAMBIOS:
- <cambio concreto 1>
- <cambio concreto 2>
NO TOCAR: <lo que queda fuera de alcance>
ACEPTACIÓN: <cómo se sabe que quedó bien: comando, prueba, comportamiento>
```

Si no conoces las rutas, primero lanza `explorador` con una pregunta concreta. No leas tú los archivos.

## 2. Partición

- Si los cambios son independientes (archivos distintos), lanza varios `implementador` en paralelo, uno por bloque, en el mismo mensaje.
- Si dependen unos de otros, uno solo con la especificación completa.
- Nunca más de 4 agentes en paralelo.

## 3. Verificación

Cuando el implementador responda, lanza `verificador`. Si falla:
- Error concreto y acotado → nuevo `implementador` con el error exacto y la corrección esperada.
- Tras 2 intentos fallidos, o si el error revela un problema de diseño → vuelve a la conversación con el usuario; no sigas iterando.

## 4. Reporte al usuario

Máximo 6 líneas: qué quedó hecho, qué pasa o falla, qué decisión queda pendiente.

## Reglas

- No escribas código en la conversación principal salvo cambios de menos de ~10 líneas en un solo archivo.
- No pidas a los agentes que devuelvan código ni logs completos.
- Escalar a Opus (`model: opus` en la llamada del agente) solo si el usuario lo autoriza o si Sonnet falló dos veces en lo mismo.
