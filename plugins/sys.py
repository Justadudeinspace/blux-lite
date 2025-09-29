# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: sys
Commands:
  blux sys info        # show environment, key paths
  blux sys engines     # engine availability
  blux sys storage     # models dir usage
"""
import os, platform
from pathlib import Path
import click
from blux.settings import SETTINGS, ROOT
from blux.engines import (
    engines_installed,
    llama_bin,
    alpaca_bin,
    ollama_present,
    openai_enabled,
)


def _dir_stats(p: Path):
    total = 0
    count = 0
    for r, dnames, fnames in os.walk(p):
        for f in fnames:
            try:
                total += (Path(r) / f).stat().st_size
                count += 1
            except Exception:
                pass
    return total, count


def _j(obj):
    import json

    return json.dumps(obj, indent=2, ensure_ascii=False)


def register(cli):
    @cli.group(name="sys")
    def group():
        """System & environment helpers."""
        pass

    @group.command("info")
    def info():
        click.echo(f"BLUX ROOT : {ROOT}")
        click.echo(f"Models Dir: {SETTINGS.get('models_dir')}")
        click.echo(f"LibF Dir  : {SETTINGS.get('libf_memory_dir')}")
        click.echo(f"Bin Dir   : {SETTINGS.get('bin_dir')}")
        click.echo("")
        click.echo(
            f"OS        : {platform.system()} {platform.release()} ({platform.machine()})"
        )
        click.echo(f"Python    : {platform.python_version()}")

    @group.command("engines")
    def engines():
        flags = engines_installed()
        click.echo(_j(flags))
        click.echo("")
        click.echo(f"llama bin  : {llama_bin() or '(not found)'}")
        click.echo(f"alpaca bin : {alpaca_bin() or '(not found)'}")
        click.echo(f"ollama     : {'yes' if ollama_present() else 'no'}")
        click.echo(f"openai API : {'yes' if openai_enabled() else 'no'}")

    @group.command("storage")
    def storage():
        p = Path(str(SETTINGS.get("models_dir"))).expanduser()
        p.mkdir(parents=True, exist_ok=True)
        total, count = _dir_stats(p)
        click.echo(f"Models path : {p}")
        click.echo(f"File count  : {count}")
        click.echo(f"Disk usage  : {total/1024/1024:.2f} MB")
