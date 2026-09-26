# skills-optimizacion

Kit transversal para Claude Code. Objetivo: **gastar el modelo caro solo donde piensa, no donde ejecuta.**

| Dónde | Modelo | Qué hace |
|---|---|---|
| Conversación contigo | Opus al planear, Sonnet al ejecutar (`opusplan`) | Diseño, arquitectura, decisiones |
| `explorador` | Haiku | Buscar y ubicar código (solo lectura) |
| `implementador` | Sonnet | Escribir código según especificación |
| `verificador` | Haiku | Lint, typecheck, pruebas, build |
| `revisor` | Sonnet | Revisar el diff antes de push |
| Cualquier otro agente | Sonnet (por defecto) | — |

## Instalación (una vez por computador)

```bash
git clone https://github.com/Ingenio-Advice/Skillset-Claude-optimizacion.git ~/skills-optimizacion
~/skills-optimizacion/install.sh
```

Reinicia Claude Code. Desde ahí aplica a **todos** los proyectos, nuevos o existentes, sin configurar nada en cada uno.

Actualizar: `cd ~/skills-optimizacion && git pull` (quedan enlazados; no hay que reinstalar).

## Instalación en la nube (claude.ai/code y sesiones en la nube de la app)

Cada sesión en la nube arranca con un `~/.claude` limpio. El kit se instala desde el **setup script** del entorno, que corre antes de cada sesión.

En la app: menú del entorno de nube (barra de título de la sesión) → **Edit** → **Setup script**. Agrega al final:

```bash
git clone --depth 1 https://github.com/Ingenio-Advice/Skillset-Claude-optimizacion.git ~/skills-optimizacion \
  && ~/skills-optimizacion/install.sh \
  || echo "skills-optimizacion: no se pudo instalar; la sesión sigue sin el kit"
```

Se hace una vez por entorno (no por proyecto). Si falla, la sesión arranca igual, sin el kit.

## Qué instala

- `~/.claude/agents/`: los 4 agentes con su modelo fijo.
- `~/.claude/skills/`: `delegar`, `cerrar`, `dieta-contexto`.
- `~/.claude/CLAUDE.md`: bloque de reglas de consumo (entre marcadores; se reemplaza al reinstalar y no toca tus otras reglas).
- `~/.claude/settings.json`: `model: opusplan` y `CLAUDE_CODE_SUBAGENT_MODEL: sonnet`. Deja un respaldo `.bak`.

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

Si Sonnet falla dos veces en lo mismo, el skill `delegar` vuelve a ti en vez de seguir intentando. Tú decides si se escala.
