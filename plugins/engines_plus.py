# -*- coding: utf-8 -*-
"""
BLUX Lite — Engines+

Modding theme: quick "upgrades & tweaks" helpers that generate drop-in run commands
for popular servers and compose files.

Commands:
  blux engines+ tgi-compose --model-id <hf_id> [--port 8080]
  blux engines+ vllm-run --model <hf_id> [--enable-lora] [--port 8000]
  blux engines+ llamacpp-run --model <gguf|hf_id> [--lora path] [--port 8080]
  blux engines+ sglang-run --model <hf_id> [--port 30000]

References:
- Hugging Face TGI docs (high-performance serving)
- vLLM CLI docs (OpenAI-compatible server)
- llama.cpp server docs (OpenAI-compatible; supports --lora for GGUF LoRA)
- SGLang docs (router, KV cache, etc.)
"""
from __future__ import annotations
from pathlib import Path
import click


def register(cli: click.Group) -> None:
    @cli.group(name="engines+")
    def engines_plus():
        """Extra engine helpers (TGI/vLLM/llama.cpp/SGLang)."""
        pass

    @engines_plus.command("tgi-compose")
    @click.option(
        "--model-id",
        required=True,
        help="HF model id to serve (e.g., meta-llama/Llama-3-8B-Instruct)",
    )
    @click.option("--port", type=int, default=8080, show_default=True)
    def tgi_compose(model_id: str, port: int):
        yml = f"""version: "3.9"
services:
  tgi:
    image: ghcr.io/huggingface/text-generation-inference:latest
    ports: ["{port}:80"]
    environment:
      - MODEL_ID={model_id}
      - NUM_SHARD=1
    volumes:
      - ~/.cache/huggingface:/data
"""
        click.echo(yml)

    @engines_plus.command("vllm-run")
    @click.option("--model", required=True, help="HF model id or path")
    @click.option(
        "--enable-lora",
        is_flag=True,
        help="Enable LoRA support (adapters can be loaded via REST)",
    )
    @click.option("--port", type=int, default=8000, show_default=True)
    def vllm_run(model: str, enable_lora: bool, port: int):
        extras = " --enable-lora" if enable_lora else ""
        click.echo(f"vllm serve {model} --port {port}{extras}")

    @engines_plus.command("llamacpp-run")
    @click.option(
        "--model", required=True, help="GGUF path or -hf <repo>/<model>:<quant>"
    )
    @click.option("--lora", default=None, help="Optional GGUF LoRA path")
    @click.option("--port", type=int, default=8080, show_default=True)
    def llamacpp_run(model: str, lora: str | None, port: int):
        lora_arg = f" --lora {lora}" if lora else ""
        click.echo(f"llama-server -m {model}{lora_arg} --port {port}")

    @engines_plus.command("sglang-run")
    @click.option("--model", required=True, help="HF model id or local path")
    @click.option("--port", type=int, default=30000, show_default=True)
    def sglang_run(model: str, port: int):
        click.echo(f"python -m sglang.launch_server --model-path {model} --port {port}")
