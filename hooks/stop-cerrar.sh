#!/usr/bin/env bash
# Stop: si quedaron cambios sin commit, sugiere /cerrar al usuario (una vez por cada conjunto de cambios).
input="$(cat)"
printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
status="$(git status --porcelain 2>/dev/null)"
[ -z "$status" ] && exit 0
sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
mark="${TMPDIR:-/tmp}/skills-optimizacion-stop-${sid:-x}"
sum="$(printf '%s' "$status" | cksum | cut -d' ' -f1)"
[ "$(cat "$mark" 2>/dev/null)" = "$sum" ] && exit 0
echo "$sum" > "$mark"
n="$(printf '%s\n' "$status" | wc -l | tr -d ' ')"
printf '{"systemMessage":"%s archivo(s) con cambios sin commit. Cuando termines, usa /cerrar."}\n' "$n"
