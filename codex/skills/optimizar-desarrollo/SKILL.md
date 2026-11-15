---
name: optimizar-desarrollo
description: Organiza tareas de software con un ejecutor económico por defecto y conserva las decisiones en el modelo principal elegido por el usuario.
---

# Optimizar desarrollo

Al iniciar trabajo de software, conserva el modelo que eligió el usuario para entender el objetivo, discutir arquitectura, tomar decisiones y revisar resultados. Optimiza el costo total para el usuario hasta una solución correcta: modelo, contexto, coordinación y reintentos. No selecciones un modelo más caro por interés comercial ni sacrifiques calidad por reducir tokens. Clasifica la tarea por alcance, riesgo y claridad antes de delegar. Consulta instrucciones del proyecto y permisos vigentes; no amplíes la autorización del usuario.

Si la especificación está cerrada y la delegación compensa su coordinación, usa `delegar`. Para trabajo trivial, resuélvelo directamente si coordinar cuesta más. La conversación principal evita redactar bloques de código de más de unas diez líneas. Un solo agente escribe cada alcance a la vez.

Un único `implementador` (Sol, medio) explora lo necesario, implementa y ejecuta verificaciones pertinentes por defecto. Reutilízalo para seguimientos del mismo alcance. Usa `explorador` o `verificador` (Luna) sólo para lotes mecánicos o búsquedas acotadas cuyo ahorro compense la transferencia. Pide revisión independiente a `revisor` (Sol, alto) sólo ante riesgo significativo —seguridad, autenticación, pagos, migraciones, concurrencia o diff amplio— o un requisito del usuario o repositorio. El principal conserva arquitectura y cambios de alcance; evita supervisión redundante, lecturas repetidas y reportes duplicados. Nunca omitas validaciones relevantes para ahorrar recursos.

Comprueba que el modelo solicitado está disponible. Si falta, comunica la limitación y usa un sustituto disponible de capacidad y costo comparables cuando la autorización lo permita; pide decisión si aumenta materialmente el costo o compromete calidad. No cambies silenciosamente al principal ni a Astra. Un fallo admite un ajuste focal y una nueva comprobación antes de escalar con evidencia.

Un subagente activo por defecto; hasta tres sólo para tareas independientes con beneficio claro, siempre máximo cuatro agentes contando al principal. No uses agente `fork` ni Workflow. No crees agentes descendientes sin coordinación. No programes seguimiento de PR, recordatorios ni consultas repetidas salvo petición expresa; tras abrir un PR, informa su enlace y termina. Registra métricas sólo si ya están disponibles, sin sondeos extra ni promesas de ahorro.
