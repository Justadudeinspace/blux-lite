# -*- coding: utf-8 -*-
"""
BLUX Lite — AIK Mobile / Android Image Kitchen

Integrates with AIK (Android Image Kitchen) and AIK Mobile.
- Unpack/repack boot/recovery images via upstream scripts when present.

Sources:
- AIK XDA thread: https://xdaforums.com/t/tool-android-image-kitchen-unpack-repack-kernel-ramdisk-win-android-linux-mac.2073775/
- AIK Mobile (Android): https://xdaforums.com/t/tool-aik-android-image-kitchen-mobile-modify-ramdisks-on-the-go-27-01-15.3013734/
- GitHub (AIK): https://github.com/osm0sis/Android-Image-Kitchen
"""
from __future__ import annotations
import os, subprocess, shutil
from pathlib import Path
import click


def _which(name: str) -> str | None:
    return shutil.which(name)


def _run(cmd: list[str]) -> int:
    return subprocess.call(cmd)


def register(cli: click.Group) -> None:
    @cli.group(name="aik")
    def aik():
        """Android Image Kitchen helpers (desktop & mobile)."""
        pass

    @aik.command("doctor")
    def doctor():
        # Typical paths
        home = Path.home()
        aik_mobile = Path("/data/local/AIK-MOBILE") if os.name != "nt" else None
        unpack = shutil.which("unpackimg.sh") or shutil.which("unpackimg.bat")
        repack = shutil.which("repackimg.sh") or shutil.which("repackimg.bat")
        click.echo(
            f"AIK Mobile dir: {aik_mobile if aik_mobile and aik_mobile.exists() else '(not found)'}"
        )
        click.echo(f"unpackimg: {unpack or '(not in PATH)'}")
        click.echo(f"repackimg: {repack or '(not in PATH)'}")

    @aik.command("unpack")
    @click.argument("img")
    def unpack(img: str):
        exe = shutil.which("unpackimg.sh") or shutil.which("unpackimg.bat")
        if not exe:
            raise click.ClickException(
                "AIK unpack script not in PATH. Place AIK folder in PATH or run from its directory."
            )
        _run([exe, img])

    @aik.command("repack")
    def repack():
        exe = shutil.which("repackimg.sh") or shutil.which("repackimg.bat")
        if not exe:
            raise click.ClickException("AIK repack script not in PATH.")
        _run([exe])
