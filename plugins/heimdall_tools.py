# -*- coding: utf-8 -*-
"""
BLUX Lite — Heimdall (Samsung flashing) helpers

Sources:
- Heimdall project: https://github.com/Benjamin-Dobell/Heimdall
"""
from __future__ import annotations
import shutil, subprocess
import click


def _which(name: str) -> str | None:
    return shutil.which(name)


def _run(cmd: list[str]) -> int:
    return subprocess.call(cmd)


def register(cli: click.Group) -> None:
    @cli.group(name="heimdall")
    def heimdall():
        """Heimdall wrappers (Samsung Odin protocol)."""
        pass

    @heimdall.command("doctor")
    def doctor():
        exe = _which("heimdall")
        click.echo(f"heimdall: {exe or '(not found)'}")
        if not exe:
            click.echo(
                "Install via your distro or build from source (see GitHub project)."
            )

    @heimdall.command("print-pit")
    def print_pit():
        exe = (
            _which("heimdall")
            or click.secho("heimdall not in PATH", fg="red")
            or exit(1)
        )
        _run([exe, "print-pit"])

    @heimdall.command("flash")
    @click.option("--ap", default=None, help="AP tar or img")
    @click.option("--bl", default=None, help="BL img")
    @click.option("--cp", default=None, help="CP img")
    @click.option("--csc", default=None, help="CSC img")
    def flash(ap, bl, cp, csc):
        exe = (
            _which("heimdall")
            or click.secho("heimdall not in PATH", fg="red")
            or exit(1)
        )
        args = [exe, "flash"]
        if ap:
            args += ["--AP", ap]
        if bl:
            args += ["--BL", bl]
        if cp:
            args += ["--CP", cp]
        if csc:
            args += ["--CSC", csc]
        _run(args)
