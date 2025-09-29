# -*- coding: utf-8 -*-
"""
BLUX Lite — GGUF Tools

Modding theme: upgrades & tweaks for GGUF models — search, download, and recommend
quantization profiles.

Commands:
  blux gguf search "<query>"            # search HF for GGUF repos/files
  blux gguf pull --repo <id> [--include *.gguf]  # download GGUFs into models_dir
  blux gguf recommend --vram 6 --cpu            # quick quant suggestion (heuristic)

References:
- GGUF usage with llama.cpp on Hugging Face.
"""
from __future__ import annotations
from pathlib import Path
import re
import click
from huggingface_hub import HfApi
from blux.settings import SETTINGS
from blux.models import hf_download

MODELS_DIR = Path(SETTINGS.get("models_dir")).expanduser()


def register(cli: click.Group) -> None:
    @cli.group()
    def gguf():
        """GGUF helpers (search/download/recommend)."""
        pass

    @gguf.command("search")
    @click.argument("query", nargs=-1, required=True)
    def search_cmd(query):
        q = " ".join(query) + " gguf"
        api = HfApi()
        # Search models with GGUF filenames
        results = api.list_models(search=q, sort="downloads", direction=-1, limit=20)
        for m in results:
            has_gguf = any(
                (a.rfilename or "").lower().endswith(".gguf")
                for a in (m.siblings or [])
            )
            if has_gguf:
                dls = getattr(m, "downloads", None)
                dls_str = f"{dls}" if dls is not None else "n/a"
                click.echo(f"- {m.id}   (likes={m.likes}  downloads≈{dls_str})")

    @gguf.command("pull")
    @click.option(
        "--repo",
        required=True,
        help="HF repo id, e.g. TheBloke/Mistral-7B-Instruct-v0.2-GGUF",
    )
    @click.option("--include", default="*.gguf", show_default=True)
    def pull_cmd(repo: str, include: str):
        MODELS_DIR.mkdir(parents=True, exist_ok=True)
        ok = hf_download(repo, include, MODELS_DIR)
        if not ok:
            raise click.ClickException(
                "Download failed; ensure Hugging Face CLI is installed / token set if required."
            )
        click.secho(f"Saved → {MODELS_DIR}", fg="green")

    @gguf.command("recommend")
    @click.option("--vram", type=float, required=True, help="GPU memory (GB)")
    @click.option("--cpu", is_flag=True, help="Target CPU-only")
    def recommend_cmd(vram: float, cpu: bool):
        # Heuristic: prefer Q6_K ~1.2x params bytes, Q5_K_M ~1.0x, Q4_K_M ~0.8x
        # Rough guide for 7B: Q4_K_M≈4GB, Q5_K_M≈5GB, Q6_K≈6–7GB
        if cpu:
            click.echo("CPU: try Q4_K_M (fast) or Q5_K_M (better quality).")
            return
        if vram < 6:
            click.echo("GPU VRAM <6GB: try Q4_K_M.")
        elif vram < 10:
            click.echo("GPU VRAM 6–10GB: try Q5_K_M.")
        else:
            click.echo("GPU VRAM >=10GB: try Q6_K or Q8_0 if memory allows.")
