# -*- coding: utf-8 -*-
"""
BLUX Lite — Modpacks (prompt/params tweaks)

Modding theme: YAML "modpacks" that tweak prompts and generation params. Apply them
to requests or shell out suggested engine args.

- `blux mods new <name>` — create a sample mod YAML
- `blux mods list` — list available modpacks
- `blux mods show <name>` — print full YAML
- `blux mods apply <name>` — print JSON of merged params (stdin can provide a base JSON)

YAML schema keys (all optional):
  system: str                  # system prompt to prepend
  preset: str                  # label
  params:                      # generation params
    temperature: float
    top_p: float
    top_k: int
    max_tokens: int
    stop: [str, ...]

Stored under ~/.config/blux-lite-gold/modpacks/<name>.yaml
"""
from __future__ import annotations
import sys, json, yaml
from pathlib import Path
import click
from blux.settings import SETTINGS

MOD_DIR = Path(SETTINGS.get("config_dir")) / "modpacks"


def _path(name: str) -> Path:
    return MOD_DIR / (name + ".yaml")


def register(cli: click.Group) -> None:
    @cli.group(name="mods")
    def mods():
        """Prompt & parameter modpacks."""
        pass

    @mods.command("new")
    @click.argument("name")
    def new_cmd(name: str):
        MOD_DIR.mkdir(parents=True, exist_ok=True)
        p = _path(name)
        if p.exists():
            raise click.ClickException(f"Modpack exists: {p}")
        sample = {
            "preset": "balanced",
            "system": "You are BLUX Lite — concise, helpful, safe.",
            "params": {
                "temperature": 0.7,
                "top_p": 0.9,
                "max_tokens": 512,
                "stop": ["\n\nUser:"],
            },
        }
        import yaml as _yaml

        p.write_text(_yaml.safe_dump(sample, sort_keys=False), encoding="utf-8")
        click.secho(f"Created {p}", fg="green")

    @mods.command("list")
    def list_cmd():
        if not MOD_DIR.exists():
            click.echo("(no modpacks)")
            return
        for yml in sorted(MOD_DIR.glob("*.yaml")):
            click.echo(f"- {yml.stem}  ({yml})")

    @mods.command("show")
    @click.argument("name")
    def show_cmd(name: str):
        p = _path(name)
        if not p.exists():
            raise click.ClickException(f"Not found: {p}")
        click.echo(p.read_text(encoding="utf-8"))

    @mods.command("apply")
    @click.argument("name")
    @click.option(
        "--base",
        type=str,
        default=None,
        help="Optional base JSON string (otherwise read from stdin)",
    )
    def apply_cmd(name: str, base: str | None):
        import copy, yaml as _yaml

        p = _path(name)
        if not p.exists():
            raise click.ClickException(f"Not found: {p}")
        mod = _yaml.safe_load(p.read_text(encoding="utf-8")) or {}
        base_obj = json.loads(base) if base else json.loads(sys.stdin.read() or "{}")
        out = copy.deepcopy(base_obj)
        # Merge
        if mod.get("system"):
            out["system"] = mod["system"]
        if isinstance(mod.get("params"), dict):
            out.setdefault("params", {}).update(mod["params"])
        click.echo(json.dumps(out, indent=2))
