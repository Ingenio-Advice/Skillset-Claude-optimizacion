#!/usr/bin/env bash
# Instala el kit en ~/.claude para que aplique a TODOS los proyectos de este computador.
# Usa enlaces simbólicos: un `git pull` en este repo actualiza todo sin reinstalar.
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
SIN_CODEX=0
for a in "$@"; do [ "$a" = "--sin-codex" ] && SIN_CODEX=1; done
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$DEST/agents" "$DEST/skills"

echo "→ Agentes"
for f in "$KIT"/agents/*.md; do
  ln -sfn "$f" "$DEST/agents/$(basename "$f")"
  echo "   $(basename "$f" .md)"
done

echo "→ Skills"
for d in "$KIT"/skills/*/; do
  n="$(basename "$d")"
  ln -sfn "${d%/}" "$DEST/skills/$n"
  echo "   $n"
done

echo "→ Reglas globales (~/.claude/CLAUDE.md)"
MD="$DEST/CLAUDE.md"
touch "$MD"
if grep -q "skills-optimizacion:inicio" "$MD"; then
  # Reemplaza el bloque existente por la versión actual
  awk '/skills-optimizacion:inicio/{skip=1} !skip{print} /skills-optimizacion:fin/{skip=0}' "$MD" > "$MD.tmp" && mv "$MD.tmp" "$MD"
fi
{ [ -s "$MD" ] && echo; cat "$KIT/config/CLAUDE.md"; } >> "$MD"

echo "→ Modelo y agentes por defecto (~/.claude/settings.json)"
S="$DEST/settings.json"
[ -f "$S" ] || echo '{}' > "$S"
cp "$S" "$S.bak"
if command -v python3 >/dev/null 2>&1 && python3 -c 'import json' 2>/dev/null; then
  python3 - "$S" "$KIT/config/hooks.json" "$KIT" <<'PY'
import json, sys
p = sys.argv[1]
with open(p) as fh:
    s = json.load(fh)
s["model"] = "opusplan"
s.setdefault("env", {})["CLAUDE_CODE_SUBAGENT_MODEL"] = "sonnet"
kit_hooks = json.loads(open(sys.argv[2]).read().replace("__KIT__", sys.argv[3]))
hooks = s.setdefault("hooks", {})
for ev, entries in kit_hooks.items():
    # Quita versiones anteriores del kit y conserva los hooks propios del usuario
    keep = [e for e in hooks.get(ev, []) if "skills-optimizacion" not in json.dumps(e) and sys.argv[3] not in json.dumps(e)
            and ".claude/ganchos/trabajo-afuera.sh" not in json.dumps(e)]
    hooks[ev] = keep + entries
with open(p, "w") as fh:
    json.dump(s, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PY
elif command -v plutil >/dev/null 2>&1; then
  plutil -replace model -string opusplan "$S"
  plutil -extract env raw "$S" >/dev/null 2>&1 || plutil -insert env -dictionary "$S"
  plutil -replace env.CLAUDE_CODE_SUBAGENT_MODEL -string sonnet "$S"
  # Sin python3 no se pueden fusionar hooks: se reemplaza la sección completa
  plutil -replace hooks -json "$(sed "s#__KIT__#$KIT#g" "$KIT/config/hooks.json" | tr -d '\n')" "$S"
else
  echo "   No encontré python3 ni plutil. Agrega a mano en $S:"
  cat "$KIT/config/settings.json"
fi
echo "   Respaldo del archivo anterior: $S.bak"

if [ "$SIN_CODEX" = 1 ]; then
  echo "→ Codex: omitido (--sin-codex)"
elif [ -d "${CODEX_HOME:-$HOME/.codex}" ] || command -v codex >/dev/null 2>&1; then
  echo "→ Codex (skills, agentes, reglas compartidas y hooks)"
  PY=""
  for c in python3.13 python3.12 python3.11 python3; do
    if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2>/dev/null; then PY="$c"; break; fi
  done
  if [ -z "$PY" ]; then
    echo "   Aviso: Codex necesita Python 3.11 o superior y no lo encontré; omito Codex. Luego: python3 $KIT/codex/install.py"
  else
    "$PY" "$KIT/codex/install.py" || echo "   Aviso: la instalación de Codex falló; Claude quedó configurado."
  fi
fi

echo
echo "Listo. Cierra y vuelve a abrir Claude Code para que tome la configuración."
