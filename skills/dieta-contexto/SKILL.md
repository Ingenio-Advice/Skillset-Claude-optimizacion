---
name: dieta-contexto
description: Audita un proyecto buscando lo que infla el consumo de tokens en cada sesión (CLAUDE.md/AGENTS.md largos, instrucciones que obligan a leer documentación pesada, archivos grandes sin excluir) y propone o aplica recortes. Usar al empezar a trabajar en un repositorio nuevo o existente, o cuando el usuario diga "optimiza este repo", "dieta de contexto", "por qué consume tanto".
disable-model-invocation: true
---

# Dieta de contexto

Todo lo que está en CLAUDE.md (y lo que importa con `@archivo`) se carga en CADA sesión y en cada agente. Cada línea inútil se paga miles de veces.

## Auditoría (delega en `explorador`)

Pide al explorador que reporte, con conteo de líneas:
1. `CLAUDE.md`, `AGENTS.md`, `.claude/CLAUDE.md` y todo lo que importen con `@`.
2. Instrucciones del tipo "lee X antes de escribir código" que apunten a documentación grande (`node_modules`, docs externas, carpetas enteras).
3. Skills del proyecto (`.claude/skills/`) con más de 200 líneas.
4. Archivos de más de 1.000 líneas en el código fuente (candidatos a no leerse enteros).
5. Si existe `.claude/settings.json` y qué permisos o modelo fija.

## Criterios

- CLAUDE.md del proyecto: objetivo ≤ 60 líneas. Solo lo que aplica a casi toda tarea: stack, comandos, convenciones no obvias, prohibiciones.
- Lo específico de un área (despliegue, base de datos, diseño) → sácalo a un skill del proyecto, que solo se carga cuando se usa.
- Instrucciones de "leer documentación antes de codificar" → reemplázalas por "consulta la guía puntual del tema solo si vas a usar una API que no conoces".
- Nada de historial, bitácoras ni pendientes dentro de CLAUDE.md; eso va en archivos aparte que se leen a demanda.
- Si el archivo problemático lo regenera una herramienta (p. ej. `AGENTS.md` de `next dev`), no lo edites: agrega en `CLAUDE.md` una línea que acote la instrucción ("consulta solo la guía puntual de la API que vas a usar"). Un hallazgo de impacto alto nunca se deja "igual" sin proponer contrapeso.

## Salida

Tabla corta: hallazgo · líneas/impacto · recorte propuesto. Aplica los recortes solo con autorización del usuario; si los aplicas, hazlo con un `implementador`.

Al terminar (se apliquen o no los recortes), crea `.claude/dieta-contexto.md` con la fecha y la tabla de hallazgos (máximo 20 líneas). Ese archivo es la marca que evita que el hook de inicio vuelva a sugerir la auditoría; debe quedar en el commit para que persista también en sesiones en la nube.
