#!/usr/bin/env python3
"""Instala el paquete localmente o lo porta a un proyecto sin borrar configuración ajena."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from datetime import datetime, timezone
try:
    import tomllib
except ImportError:
    print("Error: se requiere Python 3.11 o superior para validar config.toml.", file=sys.stderr)
    sys.exit(1)


PACKAGE = Path(__file__).resolve().parent
START = "<!-- skills-optimizacion:inicio -->"
END = "<!-- skills-optimizacion:fin -->"
SKILLS = ("optimizar-desarrollo", "delegar", "iniciar-proyecto-eficiente")
SHARED_TITLES = ("## Esperas, pruebas y sesiones", "## Orden: dónde vive cada cosa")
HOOKS = (("SessionStart", "session-start.sh", "startup"),
         ("UserPromptSubmit", "prompt-delegar.sh", None),
         ("Stop", "stop-cerrar.sh", None))
AGENTS = ("explorador", "implementador", "verificador", "revisor")
SETTINGS = {
    "enabled": "true",
    "default_subagent_model": '"gpt-6-sol"',
    "default_subagent_reasoning_effort": '"medium"',
    "max_concurrent_threads_per_session": "3",
}


def safe_path(path: Path, root: Path) -> None:
    if not path.is_relative_to(root):
        raise ValueError(f"Destino fuera de la raíz: {path}")
    current = root
    for part in path.relative_to(root).parts:
        current /= part
        if current.is_symlink():
            raise ValueError(f"Enlace simbólico inesperado: {current}")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def policy(project: bool, skills_prefix: str = "~/.agents/skills", shared: str = "") -> str:
    where = "del proyecto" if project else "del perfil local"
    prefix = ".agents/skills" if project else skills_prefix
    return f"""{START}
# Uso eficiente de agentes Codex

Para trabajo de software, aplica el skill `optimizar-desarrollo` {where} y usa `delegar` cuando la especificación esté cerrada. En proyectos nuevos, usa `iniciar-proyecto-eficiente`. Las decisiones, arquitectura y conversación permanecen con el modelo principal elegido por el usuario.

Si el catálogo no muestra los skills, lee directamente `{prefix}/optimizar-desarrollo/SKILL.md`, `{prefix}/delegar/SKILL.md` y `{prefix}/iniciar-proyecto-eficiente/SKILL.md` según corresponda.

Por defecto usa un único `implementador` (Sol, medio) que explora lo necesario, implementa y verifica; reutilízalo para seguimientos. Luna sirve sólo para un lote mecánico o búsqueda acotada que compense la transferencia. `revisor` (Sol, alto) interviene sólo ante riesgo significativo —seguridad, autenticación, pagos, migraciones, concurrencia o diff amplio— o requisito del usuario o repositorio. Evita supervisión y lecturas repetidas. Un subagente activo por defecto; hasta tres sólo para tareas independientes con beneficio claro, máximo cuatro agentes contando al principal. Un escritor por alcance. Si falta el modelo, comunica y usa sustituto comparable si procede; no cambies silenciosamente al principal o Astra. Un reintento focal y luego escala con evidencia.

La conversación principal evita bloques de código de más de unas diez líneas. Resuelve tareas triviales directamente cuando delegar costaría más. No uses agente `fork` ni Workflow. No vigiles PR ni programes recordatorios sin petición expresa; abre el PR, informa el enlace y termina. Conserva verificaciones pertinentes; mide sólo con datos disponibles, sin sondeos extra ni promesas de ahorro.
{shared}{END}
"""


def shared_rules() -> str:
    """Extrae de config/CLAUDE.md (fuente única) las secciones compartidas con Claude."""
    source = PACKAGE.parent / "config" / "CLAUDE.md"
    if not source.is_file():
        print(f"Aviso: sin {source}; el bloque no incluye reglas compartidas.", file=sys.stderr)
        return ""
    lines = read_text(source).splitlines()
    out = []
    for title in SHARED_TITLES:
        start = next((i for i, l in enumerate(lines) if l.startswith(title)), None)
        if start is None:
            print(f"Aviso: no hallé la sección '{title}' en {source}.", file=sys.stderr)
            continue
        end = next((i for i in range(start + 1, len(lines))
                    if lines[i].startswith("## ") or END in lines[i]), len(lines))
        out.append("\n".join(lines[start:end]).strip())
    return ("\n" + "\n\n".join(out) + "\n") if out else ""


def merge_block(existing: str, replacement: str) -> str:
    starts, ends = existing.count(START), existing.count(END)
    if starts != ends or starts > 1:
        raise ValueError("Bloque AGENTS ambiguo; revisión manual necesaria")
    if starts:
        begin = existing.index(START)
        finish = existing.index(END) + len(END)
        if existing.index(END) < begin:
            raise ValueError("Marcadores AGENTS invertidos")
        return existing[:begin] + replacement.rstrip("\n") + existing[finish:]
    return existing.rstrip("\n") + ("\n\n" if existing.strip() else "") + replacement


def merge_config(existing: str) -> str:
    if existing.strip():
        tomllib.loads(existing)
    lines = existing.splitlines(keepends=True)
    header = re.compile(r"^\s*\[([^\]]+)\]\s*(?:#.*)?$")
    positions = [(i, match.group(1).strip()) for i, line in enumerate(lines)
                 if (match := header.match(line.rstrip("\r\n")))]
    agents = [i for i, name in positions if name == "agents"]
    if len(agents) > 1:
        raise ValueError("Secciones [agents] duplicadas")
    if agents:
        start = agents[0]
        end = next((i for i, _ in positions if i > start), len(lines))
        segment = lines[start + 1:end]
        for key, value in SETTINGS.items():
            found = [i for i, line in enumerate(segment)
                     if re.match(r"^\s*" + re.escape(key) + r"\s*=", line)]
            if len(found) > 1:
                raise ValueError(f"Clave [agents] duplicada: {key}")
            if found:
                segment[found[0]] = f"{key} = {value}\n"
            else:
                segment.append(f"{key} = {value}\n")
        lines[start + 1:end] = segment
        result = "".join(lines)
    else:
        result = existing.rstrip("\n") + ("\n\n" if existing.strip() else "")
        result += "[agents]\n" + "".join(f"{k} = {v}\n" for k, v in SETTINGS.items())
    tomllib.loads(result)
    return result


def merge_hooks(existing: str) -> str:
    kit = PACKAGE.parent
    data = json.loads(existing) if existing.strip() else {}
    hooks = data.setdefault("hooks", {})
    for event, script, matcher in HOOKS:
        # Quita rutas viejas del kit y entradas propias previas; conserva las del usuario
        keep = [e for e in hooks.get(event, [])
                if "skills-optimizacion/hooks/" not in json.dumps(e) and str(kit / "hooks") not in json.dumps(e)]
        entry = {"hooks": [{"type": "command", "command": str(kit / "hooks" / script)}]}
        if matcher:
            entry = {"matcher": matcher, **entry}
        hooks[event] = keep + [entry]
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def tilde(path: Path) -> str:
    try:
        return "~/" + str(path.relative_to(Path.home()))
    except ValueError:
        return str(path)


def plan_files(root: Path, project: bool, codex: Path, agents_home: Path) -> dict[Path, bytes]:
    bases = (root,) if project else (codex, agents_home)

    def check(path: Path) -> None:
        base = next((b for b in bases if path.is_relative_to(b)), None)
        if base is None:
            raise ValueError(f"Destino fuera de la raíz: {path}")
        safe_path(path, base)

    override = (root if project else codex) / "AGENTS.override.md"
    check(override)
    if override.exists() and read_text(override).strip():
        raise ValueError(f"AGENTS.override.md activo prevalecería sobre la política: {override}")
    planned: dict[Path, bytes] = {}
    if project:
        for name in SKILLS:
            planned[root / ".agents" / "skills" / name / "SKILL.md"] = (PACKAGE / "skills" / name / "SKILL.md").read_bytes()
        for name in AGENTS:
            planned[codex / "agents" / f"{name}.toml"] = (PACKAGE / "agents" / f"{name}.toml").read_bytes()
    agents_path = (root if project else codex) / "AGENTS.md"
    shared = "" if project else shared_rules()
    planned[agents_path] = merge_block(
        read_text(agents_path), policy(project, tilde(agents_home / "skills"), shared)).encode()
    if not project:
        config_path = codex / "config.toml"
        planned[config_path] = merge_config(read_text(config_path)).encode()
        if (PACKAGE.parent / "hooks").is_dir():
            hooks_path = codex / "hooks.json"
            planned[hooks_path] = merge_hooks(read_text(hooks_path)).encode()
        else:
            print(f"Aviso: sin {PACKAGE.parent / 'hooks'}; no se configuran hooks de Codex.", file=sys.stderr)
    for path in planned:
        check(path)
        if path.exists() and not path.is_file():
            raise ValueError(f"Destino no es archivo: {path}")
        if project and path.exists() and path.name in ("SKILL.md", *(f"{a}.toml" for a in AGENTS)):
            if path.read_bytes() != planned[path]:
                raise ValueError(f"Conflicto con archivo existente: {path}")
    return {path: data for path, data in planned.items()
            if not path.exists() or path.read_bytes() != data}


def link_kit(codex: Path, agents_home: Path, dry_run: bool) -> None:
    """Instalación global: enlaza skills y agentes al repo para que `git pull` actualice todo."""
    pairs = [(PACKAGE / "skills" / n, agents_home / "skills" / n) for n in SKILLS]
    pairs += [(PACKAGE / "agents" / f"{n}.toml", codex / "agents" / f"{n}.toml") for n in AGENTS]
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
    for source, target in pairs:
        if target.is_symlink() and target.resolve() == source.resolve():
            continue
        print(("Vista previa enlace" if dry_run else "Enlazar") + f": {target} -> {source}")
        if dry_run:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.is_symlink():
            target.unlink()
        elif target.exists():
            target.rename(target.with_name(f"{target.name}.previo-{stamp}"))
        target.symlink_to(source)


def label(path: Path, root: Path, project: bool, codex: Path, agents_home: Path) -> str:
    if project:
        return str(path.relative_to(root))
    for name, base in (("codex", codex), ("agents", agents_home)):
        if path.is_relative_to(base):
            return f"{name}/{path.relative_to(base)}"
    raise ValueError(f"Destino fuera de la raíz: {path}")


def install(root: Path, project: bool, dry_run: bool, codex: Path, agents_home: Path) -> None:
    if project and (not root.is_dir() or root.is_symlink()):
        raise ValueError(f"Raíz inexistente o enlazada: {root}")
    planned = plan_files(root, project, codex, agents_home)
    if not project:
        link_kit(codex, agents_home, dry_run)
    if not planned:
        print("Sin cambios: instalación actualizada.")
        return
    for path in planned:
        print(("Vista previa" if dry_run else "Instalar") + f": {path}")
    if dry_run:
        return
    backup_root = codex / "backups" / "eficiencia-codex"
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup_dir = backup_root / stamp
    safe_path(backup_dir, codex)
    backup_dir.mkdir(mode=0o700, parents=True, exist_ok=False)
    backup_dir.chmod(0o700)
    manifest = {"mode": "project" if project else "global", "root": str(root), "files": []}
    records = {}
    for path, new_data in planned.items():
        original = path.read_bytes() if path.exists() else None
        relative = label(path, root, project, codex, agents_home)
        record = {"path": relative, "existed": original is not None,
                  "new_sha256": hashlib.sha256(new_data).hexdigest()}
        if original is not None:
            backup = backup_dir / relative
            backup.parent.mkdir(parents=True, exist_ok=True)
            backup.write_bytes(original)
            backup.chmod(0o600)
            record["old_sha256"] = hashlib.sha256(original).hexdigest()
            record["old_mode"] = path.stat().st_mode & 0o777
        manifest["files"].append(record)
        records[path] = record
    manifest_path = backup_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    manifest_path.chmod(0o600)
    written = []
    try:
        for path, data in planned.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.name == "hooks.json" and path.exists():
                path.with_name("hooks.json.bak").write_bytes(path.read_bytes())
            fd, temp_name = tempfile.mkstemp(prefix=".eficiencia-", dir=path.parent)
            try:
                with os.fdopen(fd, "wb") as handle:
                    handle.write(data)
                if path.exists():
                    os.chmod(temp_name, path.stat().st_mode & 0o777)
                os.replace(temp_name, path)
                written.append(path)
            finally:
                if os.path.exists(temp_name):
                    os.unlink(temp_name)
    except OSError:
        for path in reversed(written):
            backup = backup_dir / records[path]["path"]
            if backup.exists():
                path.write_bytes(backup.read_bytes())
                path.chmod(records[path]["old_mode"])
            else:
                path.unlink(missing_ok=True)
        raise
    print(f"Respaldo y manifest: {backup_dir}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Muestra destinos sin escribir")
    parser.add_argument("--project", type=Path, metavar="ROOT", help="Porta el paquete al proyecto")
    parser.add_argument("--home", type=Path, help="Perfil local alternativo; útil para pruebas")
    args = parser.parse_args()
    if args.project and args.home:
        parser.error("--project y --home son excluyentes")
    if args.project:
        root = args.project.absolute()
        codex, agents_home = root / ".codex", root / ".agents"
    elif args.home:
        root = args.home.absolute()
        codex, agents_home = root / ".codex", root / ".agents"
    else:
        root = Path.home()
        codex = Path(os.environ.get("CODEX_HOME") or root / ".codex").expanduser().absolute()
        agents_home = Path(os.environ.get("AGENTS_HOME") or root / ".agents").expanduser().absolute()
    try:
        install(root, bool(args.project), args.dry_run, codex, agents_home)
    except (OSError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
