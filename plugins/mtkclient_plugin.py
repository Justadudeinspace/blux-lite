# -*- coding: utf-8 -*-
"""
BLUX Lite — MTKClient Integration

Wraps common bkerler/mtkclient operations; supports Termux hints.
Sources:
- GitHub: https://github.com/bkerler/mtkclient
- Termux mods: https://github.com/vaginessa/termux-mtkclient
- XDA guide: https://xdaforums.com/t/guide-mtk-how-to-use-mtkclient-and-set-it-up.4509245/
"""
from __future__ import annotations
import os, shutil, subprocess
import click


def _which(name: str) -> str | None:
    return shutil.which(name)


def _run(cmd: list[str]) -> int:
    return subprocess.call(cmd)


def register(cli: click.Group) -> None:
    @cli.group(name="mtk")
    def mtk():
        """MediaTek mtkclient helpers (flash/dump/dauth)."""
        pass

    @mtk.command("doctor")
    def doctor():
        py = shutil.which("python3") or shutil.which("python")
        mtkbin = shutil.which("mtk")
        click.echo(f"python: {py or '(not found)'}")
        click.echo(f"mtk script: {mtkbin or '(mtk not in PATH)'}")
        if "TERMUX_VERSION" in os.environ:
            click.echo(
                "Termux detected. Use termux-mtkclient repo or proot-distro Ubuntu + usbutils/libusb."
            )

    @mtk.command("pip-install")
    @click.option("--user", is_flag=True, help="Use pip --user")
    def pip_install(user: bool):
        py = shutil.which("python3") or shutil.which("python") or "python3"
        cmd = [py, "-m", "pip", "install", "-U", "mtkclient"]
        if user:
            cmd.append("--user")
        _run(cmd)

    @mtk.command("run")
    @click.argument("args", nargs=-1)
    def run(args):
        """Pass-through to `mtk` script (e.g., `blux mtk run r --preloader pre.bin`)."""
        exe = (
            _which("mtk")
            or click.secho("mtk not in PATH (pip install mtkclient)", fg="red")
            or exit(1)
        )
        _run([exe] + list(args))
