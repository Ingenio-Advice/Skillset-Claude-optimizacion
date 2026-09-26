#!/usr/bin/env bash
# SessionStart: si el repo nunca pasó por /dieta-contexto, pide a Claude sugerirlo.
# La marca es .claude/dieta-contexto.md (la crea la skill), así persiste también en la nube.
cat >/dev/null
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -f "$root/.claude/dieta-contexto.md" ] && exit 0
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"skills-optimizacion: este repositorio no tiene auditoría de contexto (.claude/dieta-contexto.md). En tu primera respuesta, sugiere al usuario en una línea ejecutar /dieta-contexto antes de trabajar. No la ejecutes sin que lo pida."}}
JSON
