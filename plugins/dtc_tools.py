# -*- coding: utf-8 -*-
"""
BLUX Lite — DTC (Device Tree Compiler) helpers

Sources:
- dtc upstream: https://github.com/dgibson/dtc
- Manpage: https://manpages.ubuntu.com/manpages/trusty/man1/dtc.1.html
"""
from __future__ import annotations
import shutil, subprocess
import click


def _which(name: str) -> str | None:
    return shutil.which(name)


def _run(cmd: list[str]) -> int:
    return subprocess.call(cmd)


def register(cli: click.Group) -> None:
    @cli.group(name="dtc")
    def dtc():
        """Device Tree Compiler (compile/decompile dtb/dts)."""
        pass

    @dtc.command("decompile")
    @click.argument("dtb")
    @click.argument("out_dts")
    def decompile(dtb, out_dts):
        exe = _which("dtc") or click.secho("dtc not in PATH", fg="red") or exit(1)
        _run([exe, "-I", "dtb", "-O", "dts", "-o", out_dts, dtb])

    @dtc.command("compile")
    @click.argument("dts")
    @click.argument("out_dtb")
    def compile(dts, out_dtb):
        exe = _which("dtc") or click.secho("dtc not in PATH", fg="red") or exit(1)
        _run([exe, "-I", "dts", "-O", "dtb", "-o", out_dtb, dts])
