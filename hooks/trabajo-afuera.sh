#!/usr/bin/env bash
# Gancho PreToolUse (Bash): bloquea el trabajo pesado en el Mac (8 GB) y apunta al VPS o a GitHub.
# Lee el JSON del gancho por stdin. Sin coincidencia: no imprime nada y sale 0 (deja pasar).

# Fuera de macOS (p. ej. sesiones en la nube, Linux) el trabajo pesado sí puede
# correr ahí: el gancho no actúa.
[ "$(uname -s)" = "Darwin" ] || exit 0

entrada="$(cat)"
comando="$(printf '%s' "$entrada" | jq -r '.tool_input.command // ""' 2>/dev/null)"

[ -z "$comando" ] && exit 0

# Salida permitida: se forzó local a propósito.
[ "${TUNOM_LOCAL:-}" = "1" ] && exit 0
printf '%s' "$comando" | grep -Eq '(^|[[:space:]])TUNOM_LOCAL=1([[:space:]]|$)' && exit 0

# Lo que YA va al VPS no se juzga: se recorta antes de buscar lo pesado, en vez
# de dejar pasar el comando entero. Cubre el comando global `remoto` y el script
# del proyecto `…/remoto.sh`, solos o detrás de un `cd … &&`.
#
# Se recorta y no se sale con 0 porque «remoto npm ci && npm run build» manda al
# VPS la instalación y deja el build en el Mac: recortando, lo que queda después
# del && se sigue juzgando y se bloquea. Esa era la razón de que un agente, al
# toparse con el bloqueo de un `cd … && remoto npm install`, terminara metiendo
# el comando en un archivo temporal para que el gancho no lo viera por texto.
recorte='(^|[;&|(])[[:space:]]*(([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*)(bash[[:space:]]+)?([^[:space:];&|()]*/)?remoto(\.sh)?([[:space:]]+[^;&|()]*)?'
comando="$(printf '%s' "$comando" | sed -E "s@${recorte}@\1@g")"
[ -z "$(printf '%s' "$comando" | tr -d '[:space:];&|()')" ] && exit 0

# La salida concreta depende de la máquina: si el comando global está instalado
# sirve en cualquier repo; si no, se nombra el script del proyecto, y si tampoco
# hay, se le dice al agente que proponga montarlo antes de moler la máquina.
if [ -x /opt/homebrew/bin/remoto ] || command -v remoto >/dev/null 2>&1; then
  via='Mándalo al VPS: «remoto pruebas», «remoto build» o «remoto <comando>» desde la carpeta del proyecto.'
elif [ -x "$PWD/despliegue/vps/remoto.sh" ] || [ -x "${CLAUDE_PROJECT_DIR:-$PWD}/despliegue/vps/remoto.sh" ]; then
  via='Mándalo al VPS con despliegue/vps/remoto.sh (pruebas, build o un comando), o a GitHub Actions.'
else
  via='Este repo no tiene ruta remota montada: proponle al usuario montarla (ver Ingenio-Advice/ingenio-devops) o manda el trabajo a CI. No lo corras local «por esta vez».'
fi

# Un comando pesado solo cuenta si abre una instrucción (inicio, tras ; & | ( o salto de línea),
# con prefijos opcionales de variables de entorno. Así «git commit -m "pnpm test"» no se bloquea.
ini='(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
fin='([[:space:];&|)]|$)'
pm='(pnpm|npm|yarn)'
runner='((npx|pnpm exec|pnpm dlx|yarn)[[:space:]]+)?'

coincide() { printf '%s' "$comando" | grep -Eq "${ini}$1${fin}"; }

bloquear() {
  jq -nc --arg razon "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$razon}}'
  exit 0
}

cierre='Para forzarlo en local (solo en emergencia) antepón TUNOM_LOCAL=1.'

if coincide "(${pm}([[:space:]]+(run|exec))?[[:space:]]+test(:[A-Za-z0-9_-]+)?|${runner}vitest)"; then
  bloquear "Las pruebas no corren en el Mac (8 GB, se cuelga y se recalienta). ${via} ${cierre}"
fi

if coincide "(${pm}([[:space:]]+run)?[[:space:]]+build(:[A-Za-z0-9_-]+)?|${runner}esbuild)"; then
  bloquear "El build no corre en el Mac (8 GB, se cuelga y se recalienta). ${via} ${cierre}"
fi

if coincide "(${pm}([[:space:]]+run)?[[:space:]]+dev|${runner}wrangler[[:space:]]+dev|${pm}([[:space:]]+run)?[[:space:]]+vps:local)"; then
  bloquear "Los servidores de desarrollo no se levantan en el Mac (8 GB) salvo que el usuario lo pida. ${via} ${cierre}"
fi

if coincide "${pm}[[:space:]]+(install|i|ci|add)"; then
  bloquear "Instalar dependencias no se hace en el Mac (8 GB). ${via} ${cierre}"
fi

if coincide "docker[[:space:]]+((buildx|compose)[[:space:]]+)?build"; then
  bloquear "docker build no corre en el Mac (8 GB). ${via} ${cierre}"
fi

exit 0
