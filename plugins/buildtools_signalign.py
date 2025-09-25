# -*- coding: utf-8 -*-
"""
BLUX Lite — Android Buildtools helpers

Thin wrappers for zipalign & apksigner with doc links.
"""
from __future__ import annotations
import shutil, subprocess
import click


def _which(x: str) -> str | None:
    return shutil.which(x)


def _run(a: list[str]) -> int:
    return subprocess.call(a)


def register(cli: click.Group) -> None:
    @cli.group(name="buildtools")
    def bt():
        """Android build tools (zipalign/apksigner)."""
        pass

    @bt.command("zipalign")
    @click.argument("unsigned_apk")
    @click.argument("aligned_apk")
    def zipalign(unsigned_apk: str, aligned_apk: str):
        exe = (
            _which("zipalign")
            or click.secho("zipalign not in PATH", fg="red")
            or exit(1)
        )
        _run([exe, "-f", "4", unsigned_apk, aligned_apk])

    @bt.command("sign")
    @click.argument("apk")
    @click.option("--ks", required=True)
    @click.option("--ks-pass", required=True)
    @click.option("--alias", "alias_", required=True)
    @click.option("--key-pass", default=None)
    @click.option("--out", default=None)
    def sign(
        apk: str,
        ks: str,
        ks_pass: str,
        alias_: str,
        key_pass: str | None,
        out: str | None,
    ):
        exe = (
            _which("apksigner")
            or click.secho("apksigner not in PATH", fg="red")
            or exit(1)
        )
        dst = out or apk
        args = [
            exe,
            "sign",
            "--ks",
            ks,
            "--ks-pass",
            f"pass:{ks_pass}",
            "--ks-key-alias",
            alias_,
        ]
        if key_pass:
            args += ["--key-pass", f"pass:{key_pass}"]
        args += ["--out", dst, apk]
        _run(args)

    @bt.command("verify")
    @click.argument("apk")
    def verify(apk: str):
        exe = (
            _which("apksigner")
            or click.secho("apksigner not in PATH", fg="red")
            or exit(1)
        )
        _run([exe, "verify", "--verbose", apk])
