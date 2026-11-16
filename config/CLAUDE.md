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

## Orden: dónde vive cada cosa
- Código: solo en GitHub (organización Ingenio-Advice). Un proyecto nuevo nace como repo privado ahí y se trabaja en sesiones cloud; nunca como carpeta suelta en el Escritorio, Documentos o Descargas.
- En el Mac solo quedan `~/Developer/ingenio-devops` (`remoto`, vigilante del disco) y `~/Developer/skills-optimizacion` (hooks, agentes y skills de Claude). Si algo exige un clon local, va en `~/Developer/<repo>` y se borra al terminar.
- Documentos que no son código: iCloud Drive, con «Optimizar almacenamiento» (quedan en la nube). Nada de copias sueltas en el Escritorio.
- Insumos de proyecto (planos, DXF, suelos, levantamientos): viven en la rama `insumos` del repo del proyecto, carpeta `insumos/<proyecto>/<fecha>/`. Una sesión en la nube no pide archivos arrastrados al chat (no le llegan: son rutas del Mac); los trae con `git fetch origin insumos && git checkout origin/insumos -- insumos/<proyecto>`. Si faltan, pide al usuario enviarlos con la acción rápida «Enviar a proyecto» del Finder (o subirlos en github.com a la rama `insumos`).
- Cómputo en el VPS desde la nube: el mismo comando `remoto <args>` que en el Mac. En la nube viaja por GitHub Actions al VPS de pruebas y trae resultados (`--traer rutas`); corre en segundo plano (run_in_background) y espera el aviso. Producción solo por el botón «Desplegar» con aprobación del usuario. Nunca pidas llaves SSH ni las cargues como secreto de un entorno.
- Secretos (`.env`, claves, tokens): en el gestor de contraseñas o en el VPS; nunca en git ni en un chat. Si una clave aparece en un log o transcripción, avisa de inmediato para rotarla.
- Antes de borrar o mover un repo local: 1) todo empujado (ramas y cambios sin commit en `respaldo/<fecha>/…`), 2) ninguna sesión ni proceso con la carpeta como directorio de trabajo, 3) cada sesión activa ya movida a la nube o reemplazada por una sesión cloud con su resumen. Solo entonces se borra.
- Ramas: se trabaja en `claude/<tema>`, nunca directo en `main`; tras fusionar el PR, la rama local se borra.
<!-- skills-optimizacion:fin -->
