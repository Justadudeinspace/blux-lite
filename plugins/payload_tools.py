# -*- coding: utf-8 -*-
"""
BLUX Lite — Payload dump tools

Prefer payload-dumper-go; fallback to Python implementations.
Sources:
- payload-dumper-go: https://github.com/ssut/payload-dumper-go
- Python payload_dumper: https://github.com/vm03/payload_dumper
"""
from __future__ import annotations
import shutil, subprocess
import click


def _which(name: str) -> str | None:
    return shutil.which(name)


def _run(cmd: list[str]) -> int:
    return subprocess.call(cmd)


def register(cli: click.Group) -> None:
    @cli.group(name="payload")
    def payload():
        """OTA payload.bin dump helpers (Go/Python)."""
        pass

    @payload.command("go")
    @click.argument("payload_bin")
    @click.option("--out", default="out", show_default=True)
    def go(payload_bin, out):
        exe = (
            _which("payload-dumper-go")
            or click.secho("payload-dumper-go not in PATH", fg="red")
            or exit(1)
        )
        _run([exe, "-o", out, payload_bin])

    @payload.command("py")
    @click.argument("payload_bin")
    @click.option(
        "--part",
        "parts",
        multiple=True,
        help="Optional partitions to extract selectively",
    )
    def py(payload_bin, parts):
        exe = _which("payload_dumper") or _which("python3")
        if exe and exe.endswith("payload_dumper"):
            _run([exe, payload_bin])
        else:
            # try python -m payload_dumper style
            py = _which("python3") or _which("python") or "python3"
            args = [py, "-m", "payload_dumper", payload_bin]
            if parts:
                args = [
                    py,
                    "-m",
                    "payload_dumper",
                    "--partitions",
                    ",".join(parts),
                    payload_bin,
                ]
            _run(args)
