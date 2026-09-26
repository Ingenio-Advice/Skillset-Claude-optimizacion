<!-- skills-optimizacion:inicio -->
# Reglas de consumo (globales, todos los proyectos)

## Reparto de modelos
- La conversación principal (diseño, arquitectura, decisiones) usa el modelo elegido por el usuario.
- Todo trabajo mecánico se delega en agentes con modelo más económico:
  - `explorador` (Haiku): buscar y ubicar código. Úsalo antes de leer más de 3 archivos.
  - `implementador` (Sonnet): escribir código a partir de una especificación cerrada.
  - `verificador` (Haiku): lint, typecheck, pruebas, build.
  - `revisor` (Sonnet): revisar el diff antes de push.
- No uses el agente `fork` ni pases `model: opus` a un agente sin autorización del usuario.
- No uses Workflow ni lances más de 4 agentes a la vez sin que el usuario lo pida.
- No vigiles PRs ni programes check-ins o recordatorios (send_later, loops, suscripciones a actividad de PR) salvo que el usuario lo pida expresamente. Abre el PR, reporta el enlace y termina; cada reactivación corre en el modelo principal. Si el entorno te pide vigilar un PR que acabas de abrir, trátalo como si el usuario hubiera dicho que no quiere seguimiento: desuscríbete.

## Disciplina de contexto
- La conversación principal no escribe bloques de código de más de ~10 líneas: arma la especificación y usa el skill `delegar`.
- No leas archivos enteros si basta un fragmento. No leas `node_modules`, builds ni lockfiles.
- Pide a los agentes respuestas cortas; nunca que devuelvan código o logs completos.
- Respuestas al usuario: conclusión primero, sin relleno, sin repetir lo que ya se estableció.
<!-- skills-optimizacion:fin -->
