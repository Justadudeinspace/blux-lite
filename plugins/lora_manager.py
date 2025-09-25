# -*- coding: utf-8 -*-
"""
BLUX Lite — LoRA Manager

Modding theme: dynamically add, list, and generate run commands for LoRA adapters
across llama.cpp and vLLM.

Features
- `blux lora pull` — fetch LoRA from Hugging Face Hub into ~/.config/blux-lite/lora/<alias>/
- `blux lora list` — list stored adapters
- `blux lora gen-cmd` — print drop-in commands for llama.cpp server or vLLM server
- `blux lora vllm-load` — emit a ready-to-run curl to load adapter into a running vLLM server

References:
- vLLM LoRA dynamic loading (/v1/load_lora_adapter), docs vary by version. See docs.vllm.ai "LoRA Adapters".
- llama.cpp supports GGUF LoRA via `--lora` argument on llama-cli / llama-server.

"""
from __future__ import annotations
import os, json
from pathlib import Path
import click
from blux.settings import SETTINGS
from blux.models import hf_download

LORA_DIR = Path(SETTINGS.get("config_dir")) / "lora"
REGISTRY = LORA_DIR / "registry.json"


def _load_registry() -> dict:
    if REGISTRY.exists():
        try:
            return json.loads(REGISTRY.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {"adapters": {}}


def _save_registry(data: dict) -> None:
    LORA_DIR.mkdir(parents=True, exist_ok=True)
    REGISTRY.write_text(json.dumps(data, indent=2), encoding="utf-8")


def _resolve_alias_or_path(val: str) -> Path:
    p = Path(val)
    if p.exists():
        return p
    reg = _load_registry()["adapters"]
    if val in reg:
        return Path(reg[val]["path"])
    raise click.ClickException(f"Unknown adapter or path: {val}")


def register(cli: click.Group) -> None:
    @cli.group()
    def lora():
        """LoRA adapter management."""
        pass

    @lora.command("pull")
    @click.option(
        "--repo", required=True, help="HF repo id, e.g. ggml-org/LoRA-Llama-3.1-8B-..."
    )
    @click.option(
        "--include",
        default="*.gguf",
        show_default=True,
        help="Include glob (GGUF for llama.cpp, or adapter files for vLLM/PEFT).",
    )
    @click.option("--alias", required=True, help="Local name for this adapter.")
    def pull_cmd(repo: str, include: str, alias: str):
        """Download a LoRA adapter from Hugging Face into local registry."""
        dest = LORA_DIR / alias
        ok = hf_download(repo, include, dest)
        if not ok:
            raise click.ClickException("Download failed.")
        reg = _load_registry()
        reg["adapters"][alias] = {"repo": repo, "include": include, "path": str(dest)}
        _save_registry(reg)
        click.secho(f"LoRA saved → {dest}", fg="green")

    @lora.command("list")
    def list_cmd():
        """List downloaded LoRA adapters."""
        reg = _load_registry()["adapters"]
        if not reg:
            click.echo("(no adapters)")
            return
        for name, meta in reg.items():
            p = Path(meta["path"])
            files = [f.name for f in p.glob("**/*") if f.is_file()]
            click.echo(
                f"- {name}  repo={meta.get('repo','-')}  files={len(files)}  dir={p}"
            )

    @lora.command("gen-cmd")
    @click.option("--engine", type=click.Choice(["llama.cpp", "vllm"]), required=True)
    @click.option("--base", required=True, help="Base model path or HF id")
    @click.option(
        "--adapter",
        "adapter_alias_or_path",
        required=True,
        help="Adapter alias from registry or a direct path",
    )
    @click.option("--port", type=int, default=8000, show_default=True)
    def gen_cmd(engine: str, base: str, adapter_alias_or_path: str, port: int):
        """Print a drop-in command to run an engine with this LoRA adapter."""
        apath = _resolve_alias_or_path(adapter_alias_or_path)
        if engine == "llama.cpp":
            cmd = f"llama-server -m {base} --lora {apath} --port {port}"
        else:
            # vLLM: start server with LoRA enabled; adapters can be added at runtime
            cmd = f"vllm serve {base} --port {port} --enable-lora"
        click.echo(cmd)

    @lora.command("vllm-load")
    @click.option(
        "--name", required=True, help="Adapter name to register with the server"
    )
    @click.option(
        "--adapter",
        "adapter_alias_or_path",
        required=True,
        help="Adapter alias from registry or a direct path",
    )
    @click.option(
        "--server",
        default="http://localhost:8000",
        show_default=True,
        help="vLLM server base URL",
    )
    def vllm_load(name: str, adapter_alias_or_path: str, server: str):
        """Emit a curl that loads the adapter into a running vLLM server (started with --enable-lora)."""
        apath = _resolve_alias_or_path(adapter_alias_or_path)
        curl = (
            "curl -sS -X POST {srv}/v1/load_lora_adapter "
            "-H 'Content-Type: application/json' "
            '-d \'{{"lora_name":"{name}","lora_path":"{path}"}}\''
        ).format(srv=server.rstrip("/"), name=name, path=str(apath))
        click.echo(curl)
