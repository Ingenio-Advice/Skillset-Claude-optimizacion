# skills-optimizacion

Kit transversal para Claude Code. Objetivo: **gastar el modelo caro solo donde piensa, no donde ejecuta.**

| Dónde | Modelo | Qué hace |
|---|---|---|
| Conversación contigo | Opus al planear, Sonnet al ejecutar (`opusplan`) | Diseño, arquitectura, decisiones |
| `explorador` | Haiku 5.5 | Buscar y ubicar código (solo lectura) |
| `implementador` | Haiku 5.5 | Escribir código según especificación |
| `verificador` | Haiku 5.5 | Lint, typecheck, pruebas, build |
| `revisor` | Haiku 5.5 | Revisar el diff antes de push |
| Cualquier otro agente | Sonnet (por defecto) | — |

## Instalación (una vez por computador)

```bash
git clone https://github.com/Ingenio-Advice/Skillset-Claude-optimizacion.git ~/skills-optimizacion
~/skills-optimizacion/install.sh
```

Reinicia Claude Code. Desde ahí aplica a **todos** los proyectos, nuevos o existentes, sin configurar nada en cada uno.

Actualizar: `cd ~/skills-optimizacion && git pull && ./install.sh` (agentes y skills quedan enlazados, pero las reglas globales y los hooks se copian, así que hay que reinstalar).

## Sesiones en la nube

Cada sesión en la nube arranca con un `~/.claude` limpio. En el entorno: **Edit** → **Setup script**, y pega esta línea:

```bash
curl -fsSL https://raw.githubusercontent.com/Ingenio-Advice/Skillset-Claude-optimizacion/main/nube/instalar-en-nube.sh | bash
```

(Si el repo es privado, usa `GH_TOKEN` o `GITHUB_TOKEN` en el entorno y clona a mano: `git clone https://github.com/Ingenio-Advice/Skillset-Claude-optimizacion.git ~/skills-optimizacion && bash ~/skills-optimizacion/nube/instalar-en-nube.sh`.)
El script es idempotente y, si falla, la sesión arranca igual, sin el kit.

Nota: el hook `trabajo-afuera` solo actúa en macOS; en la nube no hace nada.

## Qué instala

- `~/.claude/agents/`: los 4 agentes con su modelo fijo.
- `~/.claude/skills/`: `delegar`, `cerrar`, `dieta-contexto`.
- `~/.local/bin/remoto` (solo en la nube, no en Mac): `nube/remoto` corre el comando en el VPS de pruebas por GitHub Actions y trae resultados (`remoto --ayuda`).
- `~/.claude/CLAUDE.md`: bloque de reglas de consumo (entre marcadores; se reemplaza al reinstalar y no toca tus otras reglas).
- `~/.claude/settings.json`: `model: opusplan`, `CLAUDE_CODE_SUBAGENT_MODEL: sonnet` y los hooks. Deja un respaldo `.bak`.

## Disparadores automáticos (hooks)

Solo sugieren; ninguno bloquea ni ejecuta nada por su cuenta.

| Hook | Cuándo | Qué hace |
|---|---|---|
| `session-start.sh` | Al abrir una sesión | Si el repo no tiene `.claude/dieta-contexto.md`, Claude te sugiere `/dieta-contexto`. |
| `prompt-delegar.sh` | Cada mensaje tuyo | Si pides implementar/arreglar/construir, recuerda a Claude usar `delegar`. |
| `stop-cerrar.sh` | Al terminar Claude | Vigilante de cierre: avisa (una vez por estado) de cambios sin commit, commits sin subir y procesos vivos dentro del repo. |

El instalador los agrega sin borrar tus hooks propios (requiere `python3`; sin él, reemplaza la sección de hooks completa).

## Codex

`install.sh` también configura Codex si detecta `~/.codex` (o `$CODEX_HOME`) o el comando `codex`; `--sin-codex` lo omite. Requiere Python 3.11+ (si no hay, avisa y sigue). Destinos configurables con `CODEX_HOME` (por omisión `~/.codex`) y `AGENTS_HOME` (`~/.agents`). Instala:

- `$AGENTS_HOME/skills/`: `optimizar-desarrollo`, `delegar`, `iniciar-proyecto-eficiente` (enlaces al repo).
- `$CODEX_HOME/agents/`: los 4 perfiles `.toml` (enlaces al repo) y `[agents]` en `config.toml`.
- `$CODEX_HOME/AGENTS.md`: bloque entre marcadores con la política de Codex más las secciones compartidas de `config/CLAUDE.md` (una sola fuente).
- `$CODEX_HOME/hooks.json`: los hooks de `hooks/` (respaldo `.bak`; conserva los tuyos).

Detalle en `codex/GUIA.md`; para solo Codex: `python3 codex/install.py`.

## Cómo trabajar

1. **Conversa y diseña** normalmente. Para análisis profundo, activa modo plan (Shift+Tab): ahí usa Opus.
2. Cuando esté claro qué hacer: **`/delegar`**. Se arma una especificación corta y la ejecutan los agentes.
3. Para subir: **`/cerrar`**. Verifica, revisa, hace commit, push y PR.
4. Al entrar a un repositorio por primera vez: **`/dieta-contexto`**. Detecta lo que infla cada sesión.

Hábitos que ahorran tanto como el kit:
- `/clear` al cambiar de tema. Una conversación larga relee todo su historial en cada mensaje.
- Una sesión por proyecto, no un hilo eterno.
- `/model` para cambiar a mano cuando quieras forzar un modelo.

## Escalar a Opus

Si Haiku falla dos veces en lo mismo, el skill `delegar` vuelve a ti en vez de seguir intentando. Tú decides si se escala a Sonnet u Opus.
