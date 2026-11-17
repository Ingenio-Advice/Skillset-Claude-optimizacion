#!/usr/bin/env bash
# Stop: vigilante de cierre. Antes de terminar avisa, una vez por cada estado, de:
# cambios sin commit, commits sin subir y procesos vivos con cwd dentro del repo.
# No mata nada y no termina con error por fallos propios. Compatible con bash 3.2 (macOS) y Linux.

json_esc() {
  local e
  e="$(printf '%s' "$1" | tr '\n\r\t' '   ' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
  printf '%s' "$e"
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# Ancestros del hook (incluido él mismo), como " pid pid pid ".
ancestros() {
  local p="$$" pp i=0
  printf ' %s ' "$p"
  while [ "$i" -lt 64 ]; do
    pp="$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')"
    case "$pp" in ''|*[!0-9]*|0|1) break ;; esac
    printf '%s ' "$pp"
    p="$pp"
    i=$((i + 1))
  done
}

# Procesos con cwd en alguna ruta: líneas "pid<TAB>ruta".
cwd_candidatos() {
  local out pid line d path
  if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
    pid=""
    out="$(lsof -a -d cwd -Fpn 2>/dev/null)"
    while IFS= read -r line; do
      case "$line" in
        p*) pid="${line#p}" ;;
        n*) printf '%s\t%s\n' "$pid" "${line#n}" ;;
      esac
    done <<< "$out"
  else
    for d in /proc/[0-9]*; do
      [ -d "$d" ] || continue
      pid="${d#/proc/}"
      path="$(readlink "$d/cwd" 2>/dev/null)"
      [ -n "$path" ] && printf '%s\t%s\n' "$pid" "$path"
    done
  fi
}

# Procesos vivos dentro de $1 (raíz), excluyendo ancestros, hijos directos del hook, shells y Claude.
# Imprime líneas "pid<TAB>comando".
procesos_vivos() {
  local root="$1" anc="$2" cand pid path ppid cmd first name
  cand="$(cwd_candidatos)"
  while IFS=$'\t' read -r pid path; do
    [ -n "$pid" ] || continue
    case "$path" in "$root"|"$root"/*) ;; *) continue ;; esac
    case "$anc" in *" $pid "*) continue ;; esac
    ppid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
    [ "$ppid" = "$$" ] && continue
    cmd="$(trim "$(ps -o command= -p "$pid" 2>/dev/null)")"
    [ -n "$cmd" ] || continue
    first="${cmd%% *}"
    name="${first##*/}"
    case "$name" in bash|zsh|sh|login|-bash|-zsh|-sh|lsof|ps|readlink) continue ;; esac
    case "$cmd" in *claude*) continue ;; esac
    printf '%s\t%s\n' "$pid" "$cmd"
  done <<< "$cand"
}

main() {
  local input sid cwd root es_repo=1 rama up nd nc np anc procs lista partes resumen
  local pid cmd i msg sum mark prev

  input="$(cat 2>/dev/null)"
  printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && return 0

  sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  sid="${sid//[^A-Za-z0-9_-]/}"
  cwd="$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  if [ -z "$cwd" ] || [ ! -d "$cwd" ]; then cwd="$PWD"; fi

  root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)"
  if [ -z "$root" ]; then
    es_repo=0
    root="$(cd "$cwd" 2>/dev/null && pwd -P)"
    [ -n "$root" ] || return 0
    case "$root" in "$HOME"|/) return 0 ;; esac
  fi

  nd=0; nc=0; rama=""
  if [ "$es_repo" = 1 ]; then
    nd="$(git -C "$root" status --porcelain 2>/dev/null | grep -v '\.DS_Store$' | grep -c .)"
    rama="$(git -C "$root" symbolic-ref --short -q HEAD 2>/dev/null)"
    if [ -n "$rama" ]; then
      up="$(git -C "$root" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"
      if [ -n "$up" ]; then
        nc="$(git -C "$root" rev-list --count '@{u}..HEAD' 2>/dev/null)"
      else
        nc="$(git -C "$root" log --oneline HEAD --not --remotes 2>/dev/null | grep -c .)"
      fi
      case "$rama" in main|master) nc=0 ;; esac
    fi
  fi
  nd="${nd//[!0-9]/}"; nd="${nd:-0}"
  nc="${nc//[!0-9]/}"; nc="${nc:-0}"

  anc="$(ancestros)"
  procs="$(procesos_vivos "$root" "$anc")"
  np="$(printf '%s' "$procs" | grep -c .)"
  np="${np//[!0-9]/}"; np="${np:-0}"

  if [ "$nd" -eq 0 ] && [ "$nc" -eq 0 ] && [ "$np" -eq 0 ]; then return 0; fi

  partes=""
  if [ "$nd" -gt 0 ]; then partes="$nd archivo(s) sin commit"; fi
  if [ "$nc" -gt 0 ]; then partes="${partes:+$partes; }$nc commit(s) sin subir en $rama"; fi
  if [ "$np" -gt 0 ]; then
    lista=""; i=0
    while IFS=$'\t' read -r pid cmd; do
      [ -n "$pid" ] || continue
      i=$((i + 1))
      [ "$i" -le 8 ] || continue
      lista="${lista:+$lista; }$pid ${cmd:0:40}"
    done <<< "$procs"
    [ "$np" -gt 8 ] && lista="$lista; (+$((np - 8)) más)"
    partes="${partes:+$partes; }procesos que siguen vivos: $lista"
  fi

  # Se bloquea una sola vez por cada estado.
  resumen="$partes"
  sum="$(printf '%s' "$resumen" | cksum)"
  set -- $sum
  sum="$1"
  mark="${TMPDIR:-/tmp}/vigilante-cierre-${sid:-x}"
  prev="$(cat "$mark" 2>/dev/null)"
  [ "$prev" = "$sum" ] && return 0
  printf '%s\n' "$sum" > "$mark" 2>/dev/null

  msg="Pendiente: $partes. Recuerda: sube el trabajo (commit y push a tu rama claude/…) y apaga los procesos que ya no se necesitan para liberar memoria (kill <pid>). Si alguno debe seguir corriendo a propósito, dilo al usuario en tu respuesta y termina."
  # Solo avisa (no bloquea): forzar otra vuelta a la sesión costaba tiempo y cupo.
  printf '{"systemMessage":"%s"}\n' "$(json_esc "$msg")"
  return 0
}

main
exit 0
