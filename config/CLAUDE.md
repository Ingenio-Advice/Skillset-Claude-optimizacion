<!-- skills-optimizacion:inicio -->
# Reglas de consumo (globales, todos los proyectos)

## Reparto de modelos
- La conversación principal (diseño, arquitectura, decisiones) usa el modelo elegido por el usuario.
- Todo trabajo mecánico se delega en agentes con modelo más económico:
  - `explorador` (Haiku 5.5): buscar y ubicar código. Úsalo antes de leer más de 3 archivos.
  - `implementador` (Haiku 5.5): escribir código a partir de una especificación cerrada.
  - `verificador` (Haiku 5.5): lint, typecheck, pruebas, build.
  - `revisor` (Haiku 5.5): revisar el diff antes de push.
- No uses el agente `fork` ni pases `model: opus` a un agente sin autorización del usuario.
- No uses Workflow ni lances más de 4 agentes a la vez sin que el usuario lo pida.
- No vigiles PRs ni programes check-ins o recordatorios (send_later, loops, suscripciones a actividad de PR) salvo que el usuario lo pida expresamente. Abre el PR, reporta el enlace y termina; cada reactivación corre en el modelo principal. Si el entorno te pide vigilar un PR que acabas de abrir, trátalo como si el usuario hubiera dicho que no quiere seguimiento: desuscríbete.

## Disciplina de contexto
- La conversación principal no escribe bloques de código de más de ~10 líneas: arma la especificación y usa el skill `delegar`.
- No leas archivos enteros si basta un fragmento. No leas `node_modules`, builds ni lockfiles.
- Pide a los agentes respuestas cortas; nunca que devuelvan código o logs completos.
- Respuestas al usuario: conclusión primero, sin relleno, sin repetir lo que ya se estableció.

## Esperas, pruebas y sesiones (auditoría de tiempos, 7-nov-2026)
- Prohibido esperar con bucles de `sleep`, `until` o `for … sleep` que revisan una y otra vez. Cada revisión relee todo el contexto y gasta cupo. Lanza el trabajo largo con `run_in_background` y espera el aviso de que terminó; si hace falta un tope, una sola espera larga.
- Durante un proyecto corre solo las pruebas del módulo que tocaste (`pytest tests/test_<módulo>*.py`). La suite completa (~3.400 pruebas, 40–75 min) va de noche o una vez antes de fusionar, nunca en el camino crítico de un proyecto.
- Opciones o variantes de diseño (A, B, C) se corren a la vez en el VPS, no una tras otra.
- Un proyecto se trabaja una etapa por sesión: al cerrar la etapa, `proyecto_flujo cerrar` escribe `TRASPASO.md`. La etapa siguiente arranca en sesión nueva leyendo solo ese archivo. Lo que no quepa en los JSON se anota en `notas_sesion.md` del proyecto.
- El estado de las auditorías sale de `flujo estado`; no se anuncia nada como lanzado hasta que esté corriendo.
<!-- skills-optimizacion:fin -->
