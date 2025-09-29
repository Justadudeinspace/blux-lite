# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: bench
Commands:
  blux bench local [--n 32] [--pick <gguf-path>]    # quick token run with llama/alpaca
  blux bench api   [--n 32] [--model openai:gpt-4o-mini]  # quick token run via OpenAI-compatible
"""
import time, glob
from pathlib import Path
import click
from blux.settings import SETTINGS
from blux.engines import (
    llama_bin,
    alpaca_bin,
    resolve_timeout_s,
    run_llama_like,
    openai_enabled,
)
from blux.models import run_openai_compat

PROMPT = "Say 'ready' and then count from 1 to 8."


def _first_gguf():
    root = Path(str(SETTINGS.get("models_dir"))).expanduser()
    for pat in ["*.gguf", "**/*.gguf"]:
        hits = list(root.glob(pat))
        if hits:
            return str(hits[0])
    return ""


def register(cli):
    @cli.group(name="bench")
    def group():
        """Tiny sanity checks for engines (latency-focused)."""
        pass

    @group.command("local")
    @click.option("--n", "max_tokens", type=int, default=32)
    @click.option("--pick", type=str, default="")
    def bench_local(max_tokens, pick):
        model = pick or _first_gguf()
        if not model:
            click.echo(
                "No GGUF found. Download one with: blux catalog download tinyllama"
            )
            return
        binp = llama_bin() or alpaca_bin()
        if not binp:
            click.echo("No local llama/alpaca binary. Run installer to build.")
            return
        st = time.time()
        tout = resolve_timeout_s("llama_timeout_s", None)
        out = (run_llama_like(binp, model, PROMPT, tout) or "").strip()
        dt = time.time() - st
        click.echo(f"time={dt:.2f}s  bin={Path(binp).name}  model={Path(model).name}")
        click.echo(out[:400] or "(no output)")

    @group.command("api")
    @click.option("--n", "max_tokens", type=int, default=32)
    @click.option("--model", type=str, default="openai:gpt-4o-mini")
    def bench_api(max_tokens, model):
        if not openai_enabled():
            click.echo("OPENAI-like API not configured. Set env and try again.")
            return
        if not model.startswith("openai:"):
            click.echo("Use --model openai:<model-name>")
            return
        st = time.time()
        out = (
            run_openai_compat(
                model.split(":", 1)[1],
                PROMPT,
                max_tokens,
                resolve_timeout_s("openai_timeout_s", None),
            )
            or ""
        ).strip()
        dt = time.time() - st
        click.echo(f"time={dt:.2f}s  engine=openai  model={model}")
        click.echo(out[:400] or "(no output)")
