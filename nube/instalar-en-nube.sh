#!/usr/bin/env bash
# Para pegar en el "setup script" de un entorno cloud de Claude Code (Linux).
# Clona (o actualiza) el kit en ~/skills-optimizacion y corre install.sh.
# Idempotente. Nunca rompe el arranque: ante cualquier fallo avisa y sale 0.

REPO="Ingenio-Advice/Skillset-Claude-optimizacion"
DIR="$HOME/skills-optimizacion"
TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [ -n "$TOKEN" ]; then
  URL="https://x-access-token:${TOKEN}@github.com/${REPO}.git"
else
  URL="https://github.com/${REPO}.git"
fi

if [ -d "$DIR/.git" ]; then
  git -C "$DIR" pull --ff-only --quiet "$URL" 2>/dev/null || echo "skills-optimizacion: no pude actualizar; uso la copia existente"
else
  rm -rf "$DIR"
  if ! git clone --depth 1 --quiet "$URL" "$DIR" 2>/dev/null; then
    echo "AVISO skills-optimizacion: no se pudo clonar el kit (¿repo privado sin GH_TOKEN?). La sesión sigue sin el kit."
    exit 0
  fi
fi

bash "$DIR/install.sh" || echo "AVISO skills-optimizacion: install.sh falló; la sesión sigue sin el kit."
exit 0
