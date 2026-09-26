#!/usr/bin/env bash
# UserPromptSubmit: si el mensaje pide implementar, recuerda usar la skill delegar.
input="$(cat)"
prompt="$(printf '%s' "$input" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -c 4000)"
case "$prompt" in /*) exit 0 ;; esac
if printf '%s' "$prompt" | grep -qiE '(implement|hazlo|h[aá]gal[oa]|constru[iy]|arregl|corrig|desarroll|programa|codific|refactor|manos a la obra|ejec[uú]t|\bbuild\b|\bfix\b)'; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"skills-optimizacion: si esto implica escribir más de ~10 líneas de código o leer más de 3 archivos, usa la skill delegar (implementador en Sonnet, verificador en Haiku) en lugar de hacerlo en la conversación principal."}}
JSON
fi
exit 0
