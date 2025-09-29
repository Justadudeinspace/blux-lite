# -*- coding: utf-8 -*-
"""
BLUX Lite — Compatibility Scanner

Collect device/ROM properties via adb and evaluate YAML rules to suggest
compatible mods/ROMs. (No automatic flashing.)
"""
from __future__ import annotations
import subprocess, shutil, sys, yaml
from pathlib import Path
import click


def _which(x):
    return shutil.which(x)


def _adb_out(args: list[str]) -> str:
    p = subprocess.run(
        [_which("adb") or "adb"] + args,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return p.stdout


def register(cli: click.Group) -> None:
    @cli.group(name="compat")
    def compat():
        """Scan device props and evaluate YAML compatibility rules."""
        pass

    @compat.command("props")
    def props():
        out = _adb_out(["shell", "getprop"])
        click.echo(out)

    @compat.command("eval")
    @click.option("--rules", required=True, help="YAML file with allow/deny rules")
    def eval_rules(rules: str):
        data = yaml.safe_load(Path(rules).read_text(encoding="utf-8"))
        props = _adb_out(["shell", "getprop"])

        def has(s):
            return s in props

        ok = True
        for must in data.get("require_contains", []):
            if not has(must):
                click.echo(f"missing: {must}")
                ok = False
        for forb in data.get("forbid_contains", []):
            if has(forb):
                click.echo(f"forbidden: {forb}")
                ok = False
        click.echo("OK" if ok else "NOT COMPATIBLE")
