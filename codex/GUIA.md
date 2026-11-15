# Paquete de eficiencia para Codex

El modelo principal conserva las decisiones y el diálogo. Por defecto, un `implementador` Sol medio explora lo necesario, realiza el cambio y ejecuta las verificaciones pertinentes. Luna queda para lotes mecánicos o búsquedas acotadas que compensen transferir contexto; la revisión independiente con Sol alto se reserva para riesgo significativo o requisitos expresos. Los skills buscan reducir el costo total para usted, incluidos contexto, coordinación y reintentos, sujeto a una solución correcta. Las tareas triviales pueden resolverse directamente.

Para ver los destinos previstos antes de instalarlos en este equipo:

```sh
python3 install.py --dry-run
```

Para instalarlos (o corre `install.sh` en la raíz del repo, que lo incluye):

```sh
python3 install.py
```

El instalador requiere Python 3.11 o superior para validar `config.toml` antes de tocarlo. En Codex Desktop puede usarse el Python incluido en sus dependencias si el `python3` del sistema es anterior.

La instalación global (la hace también `install.sh` del repo) enlaza los skills en `$AGENTS_HOME/skills` (por omisión `~/.agents/skills`) y los perfiles en `$CODEX_HOME/agents` (`~/.codex/agents`) apuntando al repo, así que `git pull` los actualiza. Escribe un bloque marcado en `$CODEX_HOME/AGENTS.md` (con las secciones compartidas tomadas de `config/CLAUDE.md`), fusiona `$CODEX_HOME/hooks.json` (SessionStart, UserPromptSubmit y Stop hacia `hooks/` del repo; respaldo `hooks.json.bak`) y cuatro ajustes en `[agents]` de `config.toml`. Conserva el resto de esos archivos. Los cambios aparecerán en sesiones nuevas; puede requerirse reiniciar Codex. Un skill o perfil previo que no sea enlace se renombra a `*.previo-<fecha>`. El instalador no altera el modelo principal, permisos, herramientas, conexiones, variables de entorno ni otros proyectos.

`CODEX_HOME` y `AGENTS_HOME` cambian los destinos. El instalador se detiene si encuentra un `AGENTS.override.md` activo que ocultaría las instrucciones nuevas. La vista previa enumera destinos; para inspeccionar el texto, consulta los archivos del paquete y el bloque generado antes de instalar.

Para un proyecto nuevo que vaya a ejecutarse en nube, lleva una copia portátil al repositorio después de revisar su vista previa:

```sh
python3 /ruta/del/repo/codex/install.py --project /ruta/del/proyecto --dry-run
python3 /ruta/del/repo/codex/install.py --project /ruta/del/proyecto
```

Esto crea `.agents/skills`, `.codex/agents` y un bloque en `AGENTS.md` del proyecto. Revisa y confirma esos archivos según el flujo normal del proyecto para que lleguen al host remoto. El perfil global local no se sincroniza por sí solo. Si el host remoto no recibe archivos del repositorio, incluye en el prompt de creación de la tarea la política y los modelos, o configura allí el mismo paquete. El instalador no hace commit ni push.

Cada ejecución que cambia archivos guarda un `manifest.json` y copias originales bajo `.codex/backups/eficiencia-codex/`. Para revertir, restaura desde el respaldo los archivos con `existed: true` y elimina sólo los archivos con `existed: false`, comprobando antes que coinciden con `new_sha256`; así evitas borrar cambios posteriores. Los archivos ajenos a la lista del manifest permanecen intactos.

Decisiones esperadas: una corrección cosmética corta puede resolverse sin agente; una implementación normal usa un solo Sol para cambio y verificaciones; autenticación agrega revisión independiente Sol alto y mantiene decisiones en el principal; si falta un modelo económico se comunica y se usa sustituto comparable cuando proceda, sin cambio silencioso a Astra; una tarea en nube sin los archivos portátiles recibe la política en su prompt.
