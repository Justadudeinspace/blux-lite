# -*- coding: utf-8 -*-
"""
BLUX Lite — Apktool helpers

Sources:
- Apktool: https://github.com/iBotPeaches/Apktool
"""
from __future__ import annotations
import shutil, subprocess
import click


def _which(name: str) -> str | None:
    return shutil.which(name)


def _run(cmd: list[str]) -> int:
    return subprocess.call(cmd)


def register(cli: click.Group) -> None:
    @cli.group(name="apktool")
    def apktool():
        """Decompile/build/sign APKs (wrapper around apktool)."""
        pass

    @apktool.command("decode")
    @click.argument("apk")
    @click.option("-o", "--out", default=None, help="Output directory")
    def decode(apk, out):
        exe = (
            _which("apktool")
            or click.secho("apktool not in PATH (install from upstream)", fg="red")
            or exit(1)
        )
        args = [exe, "d", apk]
        if out:
            args += ["-o", out]
        _run(args)

    @apktool.command("build")
    @click.argument("proj")
    @click.option("-o", "--out", default=None, help="Output APK path")
    def build(proj, out):
        exe = (
            _which("apktool") or click.secho("apktool not in PATH", fg="red") or exit(1)
        )
        args = [exe, "b", proj]
        if out:
            args += ["-o", out]
        _run(args)
