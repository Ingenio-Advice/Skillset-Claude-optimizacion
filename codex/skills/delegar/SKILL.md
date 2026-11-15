---
name: delegar
description: Delega una tarea de desarrollo con especificación cerrada a un agente adecuado, con contexto explícito y verificación proporcional.
---

# Delegar trabajo cerrado

Antes de delegar, define resultado observable, alcance de archivos o repositorio, restricciones, permisos, decisiones ya tomadas y criterios de aceptación. Indica qué debe devolver el agente: conclusión breve, archivos afectados, comprobaciones y dudas concretas; evita código y registros completos. Enlaza los artefactos pertinentes. No presupongas que el agente verá la conversación anterior: transfiere toda decisión necesaria, sin contexto irrelevante.

Por defecto, entrega toda la ejecución a un `implementador` Sol medio: exploración necesaria, cambio y verificaciones pertinentes. Reutiliza al mismo ejecutor para correcciones y seguimientos. Usa Luna sólo para un lote mecánico o búsqueda acotada que justifique el costo de transferir contexto. Convoca a `revisor` Sol alto sólo para seguridad, autenticación, pagos, migraciones, concurrencia, diff amplio u obligación del usuario o repositorio. En la API de colaboración, cuando fijes modelo, inicia con `fork_turns: "none"` y pasa todo el contexto en el mensaje. No uses un agente llamado `fork`.

Un subagente simultáneo por defecto; hasta tres sólo si las tareas son independientes y la concurrencia ofrece un beneficio claro. Un escritor por alcance. El principal decide arquitectura, acepta cambios de alcance y sintetiza la entrega final sin repetir el análisis, las lecturas ni el reporte del ejecutor.

Tras una respuesta, comprueba que el resultado cumple la especificación y que pasaron las verificaciones relevantes, usando el resumen del ejecutor salvo riesgo concreto que exija inspección adicional. Si falla, permite un solo reintento focal y luego escala con evidencia. Si falta el modelo económico, comunica y usa uno comparable cuando sea adecuado; consulta sólo si el sustituto aumenta materialmente costo o riesgo. Nunca prometas un ahorro numérico sin datos observados ni lances agentes o sondeos para medirlo.
