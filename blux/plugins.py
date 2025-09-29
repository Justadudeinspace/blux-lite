import json

# -*- coding: utf-8 -*-
import re, importlib.util
from pathlib import Path
import os
import click
from .settings import ROOT

PLUGINS_DIR = ROOT / "plugins"


def load_plugins(cli_group):
    if not PLUGINS_DIR.exists():
        return
    for py in sorted(PLUGINS_DIR.glob("*.py")):
        try:
            spec = importlib.util.spec_from_file_location(py.stem, py)
            if not spec or not spec.loader:
                continue
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)  # type: ignore
            if hasattr(mod, "register"):
                mod.register(cli_group)  # type: ignore
        except Exception as e:
            click.echo(f"Failed to load plugin {py.name}: {e}")


def create_plugin(description: str) -> Path:
    PLUGINS_DIR.mkdir(parents=True, exist_ok=True)
    # Slugify filename
    base = re.sub(r"[^a-zA-Z0-9]+", "_", description.strip().lower()).strip("_")
    if not base:
        base = "plugin"
    fname = f"{base}.py"
    path = PLUGINS_DIR / fname
    if path.exists():
        raise FileExistsError(f"Plugin {fname} already exists")
    template = f'''# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: {description}
"""
import click

def register(cli):
    @cli.command("{base}")
    def _cmd():
        """{description}"""
        click.echo("Hello from plugin: {description}")
'''
    path.write_text(template, encoding="utf-8")
    return path


def install_global_shim(target_name: str = "blux"):
    """
    Install a small launcher shim into a writable directory on PATH.
    Updated message to mention ~/.blux-lite per installer.
    """
    shim = """#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$ROOT/blux.py"
if [[ ! -f "$APP" ]]; then
  echo "blux shim: $APP not found. Set BLUX_ROOT or place repo under ~/.blux-lite."
  exit 1
fi
exec python3 "$APP" "$@"
"""
    candidates = []
    for key in ("HOME",):
        d = os.environ.get(key)
        if d:
            candidates.extend([Path(d) / ".local" / "bin", Path(d) / "bin"])
    # Also check PATH items
    for p in os.environ.get("PATH", "").split(os.pathsep):
        if p:
            candidates.append(Path(p))

    dest_dir = None
    for c in candidates:
        try:
            c.mkdir(parents=True, exist_ok=True)
            if c.exists() and c.is_dir() and os.access(str(c), os.W_OK):
                dest_dir = c
                break
        except Exception:
            continue
    if not dest_dir:
        click.secho("No writable bin directory found for PATH shim.", fg="yellow")
        return None
    dest = dest_dir / target_name
    dest.write_text(shim, encoding="utf-8")
    dest.chmod(0o755)
    return dest
