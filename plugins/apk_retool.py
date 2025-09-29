# -*- coding: utf-8 -*-
"""
BLUX Lite — APK Retool (safe)

Automates a *legit* reverse-engineering workflow for your *own or open-source*
APKs only:
- decode/build via apktool
- zipalign
- apksigner sign/verify

Notes:
- This plugin intentionally DOES NOT bypass signatures, SSL pinning, DRM, or
  other protections. For testing security of apps you own or have explicit
  permission to test, consult OWASP MASTG.
"""
from __future__ import annotations
import os, shutil, subprocess
from pathlib import Path
import click


def _which(x: str) -> str | None:
    return shutil.which(x)


def _run(args: list[str]) -> int:
    return subprocess.call(args)


def register(cli: click.Group) -> None:
    @cli.group(name="apk-retool")
    def grp():
        """Decode/build/sign/align APKs (ethically, for your own projects)."""
        pass

    @grp.command("decode")
    @click.argument("apk")
    @click.option("-o", "--out", default=None, help="Output dir")
    def decode(apk: str, out: str | None):
        exe = (
            _which("apktool") or click.secho("apktool not in PATH", fg="red") or exit(1)
        )
        args = [exe, "d", "-f", apk]
        if out:
            args += ["-o", out]
        _run(args)

    @grp.command("build")
    @click.argument("proj")
    @click.option("-o", "--out", default=None, help="Output APK path")
    def build(proj: str, out: str | None):
        exe = (
            _which("apktool") or click.secho("apktool not in PATH", fg="red") or exit(1)
        )
        args = [exe, "b", proj]
        if out:
            args += ["-o", out]
        _run(args)

    @grp.command("zipalign")
    @click.argument("unsigned_apk")
    @click.argument("aligned_apk")
    def zipalign(unsigned_apk: str, aligned_apk: str):
        za = (
            _which("zipalign")
            or click.secho("zipalign not in PATH", fg="red")
            or exit(1)
        )
        _run([za, "-f", "4", unsigned_apk, aligned_apk])

    @grp.command("sign")
    @click.argument("apk")
    @click.option("--ks", required=True, help="Keystore path")
    @click.option("--ks-pass", required=True, help="Keystore password")
    @click.option("--key-alias", required=True)
    @click.option("--key-pass", required=False, default=None)
    @click.option("--out", default=None, help="Output signed APK (default: in-place)")
    def sign(
        apk: str,
        ks: str,
        ks_pass: str,
        key_alias: str,
        key_pass: str | None,
        out: str | None,
    ):
        apksigner = (
            _which("apksigner")
            or click.secho("apksigner not in PATH", fg="red")
            or exit(1)
        )
        dst = out or apk
        args = [
            apksigner,
            "sign",
            "--ks",
            ks,
            "--ks-pass",
            f"pass:{ks_pass}",
            "--ks-key-alias",
            key_alias,
        ]
        if key_pass:
            args += ["--key-pass", f"pass:{key_pass}"]
        args += ["--out", dst, apk]
        _run(args)

    @grp.command("verify")
    @click.argument("apk")
    def verify(apk: str):
        apksigner = (
            _which("apksigner")
            or click.secho("apksigner not in PATH", fg="red")
            or exit(1)
        )
        _run([apksigner, "verify", "--verbose", apk])

    @grp.command("pipeline")
    @click.argument("proj_dir")
    @click.option(
        "--unsigned-apk", required=True, help="Path to apktool-built unsigned APK"
    )
    @click.option("--aligned-apk", required=True, help="Output of zipalign")
    @click.option("--signed-apk", required=True, help="Final signed APK output")
    @click.option("--ks", required=True)
    @click.option("--ks-pass", required=True)
    @click.option("--key-alias", required=True)
    @click.option("--key-pass", default=None)
    def pipeline(
        proj_dir: str,
        unsigned_apk: str,
        aligned_apk: str,
        signed_apk: str,
        ks: str,
        ks_pass: str,
        key_alias: str,
        key_pass: str | None,
    ):
        # apktool b
        build(None, proj_dir, unsigned_apk)
        # zipalign -> aligned_apk
        zipalign(unsigned_apk, aligned_apk)
        # sign -> signed_apk
        sign(aligned_apk, ks, ks_pass, key_alias, key_pass, signed_apk)
        # verify
        verify(signed_apk)
