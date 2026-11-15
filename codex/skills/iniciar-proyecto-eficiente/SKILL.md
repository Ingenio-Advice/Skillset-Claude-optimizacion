---
name: iniciar-proyecto-eficiente
description: Prepara un proyecto nuevo para usar la política de agentes económicos en Codex local o en un entorno de nube que recibe archivos del repositorio.
---

# Iniciar proyecto eficiente

La política global local sólo entra en sesiones que leen el perfil local. Antes de trabajar en un proyecto nuevo autorizado, comprueba si el proyecto ya trae instrucciones equivalentes; evita duplicarlas o reemplazarlas. Si el trabajo se ejecutará en nube o en otro host, incorpora al proyecto el paquete portátil mediante `python3 ${CODEX_HOME:-$HOME/.codex}/eficiencia-codex/install.py --project RUTA`, revisa el diff y conserva instrucciones y permisos existentes. Ese instalador queda disponible tras la instalación global. No supongas que `~/.codex` local se sincroniza a la nube. Si la nube no recibe estos archivos o no admite los modelos indicados, transfiere la política y los roles en el prompt de creación de la tarea y adapta el modelo explícitamente según lo disponible.

El bloque de arranque en `AGENTS.md` remite a `.agents/skills/optimizar-desarrollo`, `.agents/skills/delegar` y `.agents/skills/iniciar-proyecto-eficiente`; los perfiles viven en `.codex/agents`. Transfiere la pauta actual: un ejecutor Sol medio por defecto que explora, cambia y verifica; Luna sólo cuando el trabajo acotado compensa transferir contexto; revisión Sol alta sólo ante riesgo significativo o requisito explícito. Confirma que esas rutas llegan al entorno destino. Una política del proyecto o del usuario que sea más específica prevalece. No instales ni modifiques proyectos existentes ajenos a la tarea, y no hagas commit o push sin autorización incluida en el encargo.
