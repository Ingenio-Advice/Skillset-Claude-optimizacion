---
name: cerrar
description: Cierra un bloque de trabajo con el menor consumo posible - verifica, revisa el diff, hace commit y push, y abre el PR si aplica. Usar cuando el usuario diga "cierra", "sube esto", "commit", "haz el PR" o al terminar una tarea implementada.
disable-model-invocation: true
---

# Cerrar

Ciclo mecánico; nada de esto requiere el modelo principal más allá de coordinar.

1. Lanza en paralelo, en un solo mensaje:
   - `verificador`: lint, typecheck, pruebas, build.
   - `revisor`: diff actual contra la rama base.
2. Si hay fallas o hallazgos `BLOQUEANTE`: un `implementador` con la lista exacta. Luego repite el paso 1 una sola vez.
3. Si todo está limpio:
   - Mensaje de commit: una línea de resumen en imperativo + máximo 3 líneas de detalle.
   - `git add` de los archivos tocados (no `git add -A` a ciegas), commit y push a la rama de trabajo.
   - Si no hay PR abierto para la rama y el repositorio usa PRs, créalo con una descripción de máximo 10 líneas.
4. Reporta en 3 líneas: commit, estado de chequeos, enlace del PR.

Hallazgos `MENOR` del revisor: menciónalos al usuario en una línea; no los corrijas sin que lo pida.
