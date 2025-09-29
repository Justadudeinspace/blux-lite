# -*- coding: utf-8 -*-
#!/usr/bin/env python3
"""
Genkit + OpenAI terminal plugin (Click CLI)

Requirements:
  pip install "genkit[openai]" click pydantic

Env:
  OPENAI_API_KEY=sk-...

Works great with BLUX secrets loader:
  source scripts/load_secrets.sh && _blux_load_secrets ./secrets/secrets.txt
"""
from __future__ import annotations

import asyncio
import json
import os
import sys
from typing import Optional

import click
from pydantic import BaseModel, Field

# Genkit Python (OpenAI extra)
# Docs (PyPI): https://pypi.org/project/genkit/  (has 'openai' extra)
from genkit.ai import Genkit


# ---------- Schemas (structured outputs) ----------
class ChatOutput(BaseModel):
    text: str = Field(description="Primary text output")


# ---------- Core helper to make a Genkit instance ----------
def make_ai(model: str, temperature: float) -> Genkit:
    """
    Create a Genkit AI instance configured to use OpenAI models.

    Genkit uses a unified interface; the 'openai' provider is selected by
    prefixing model with 'openai/'. Examples:
      openai/gpt-4o
      openai/gpt-4.1-mini
      openai/o3-mini
    """
    # Genkit Python discovers providers by model prefix; for OpenAI,
    # installing genkit[openai] enables the provider.
    # OPENAI_API_KEY must be in the environment.
    if not os.getenv("OPENAI_API_KEY"):
        raise RuntimeError(
            "OPENAI_API_KEY not set (use secrets/secrets.txt or export it)"
        )

    # Lazy import after we’ve checked env to keep error messages crisp
    # (some environments import plugins at module import time).
    ai = Genkit(
        # No explicit plugin object needed if provider is discovered by prefix.
        # If Genkit adds explicit OpenAI plugin later, you can pass it here.
        model=model,
        temperature=temperature,
    )
    return ai


# ---------- CLI ----------
@click.group(context_settings=dict(help_option_names=["-h", "--help"]))
def cli():
    """Genkit + OpenAI CLI. Use `chat` for multi-turn or `prompt` for one-shot."""


@cli.command()
@click.argument("message", nargs=-1)
@click.option(
    "--model",
    "-m",
    default="openai/gpt-4o",
    show_default=True,
    help="OpenAI model via Genkit (prefix 'openai/...' per Genkit).",
)
@click.option("--system", "-s", default=None, help="Optional system prompt.")
@click.option("--temperature", "-t", type=float, default=0.3, show_default=True)
@click.option(
    "--json-out/--no-json-out",
    default=False,
    show_default=True,
    help="Emit JSON with tokens/metadata.",
)
def prompt(message, model, system, temperature, json_out):
    """
    One-shot text generation. Example:

      blux-genkit prompt "Write a tiny bash script to print device info"
    """
    text = " ".join(message).strip()
    if not text:
        click.echo("No prompt provided.", err=True)
        sys.exit(2)

    async def run():
        ai = make_ai(model=model, temperature=temperature)

        # If you want to enforce a schema:
        # result = await ai.generate(prompt=text, system=system, output_schema=ChatOutput)
        result = await ai.generate(prompt=text, system=system)
        # result has .output (parsed) and .raw (provider raw)
        out = result.output
        if json_out:
            click.echo(
                json.dumps(
                    {
                        "model": model,
                        "temperature": temperature,
                        "system": system,
                        "output": (
                            out if not isinstance(out, (str, bytes)) else str(out)
                        ),
                        "raw": result.raw,  # may be large; comment out if noisy
                    },
                    ensure_ascii=False,
                )
            )
        else:
            # If structured schema was used, out may be dict; handle both
            click.echo(
                out if isinstance(out, str) else json.dumps(out, ensure_ascii=False)
            )

    asyncio.run(run())


@cli.command()
@click.option("--model", "-m", default="openai/gpt-4o", show_default=True)
@click.option("--system", "-s", default="You are a helpful coding assistant.")
@click.option("--temperature", "-t", type=float, default=0.3, show_default=True)
def repl(model, system, temperature):
    """
    Lightweight multi-turn chat REPL in the terminal.

    Example:
      blux-genkit repl -m openai/gpt-4o -s "Be concise"
    """

    async def run():
        ai = make_ai(model=model, temperature=temperature)
        history = []

        click.echo(
            click.style(f"[Genkit/OpenAI] Model={model} temp={temperature}", fg="cyan")
        )
        click.echo(
            click.style(
                "Type /exit to quit, /system to change system prompt.", fg="blue"
            )
        )

        sys_prompt = system
        while True:
            try:
                user_in = input(click.style("you> ", fg="green"))
            except EOFError:
                break
            if user_in.strip() in ("/exit", "/quit"):
                break
            if user_in.startswith("/system "):
                sys_prompt = user_in[len("/system ") :].strip()
                click.echo(click.style(f"(system set: {sys_prompt})", fg="yellow"))
                continue
            if not user_in.strip():
                continue

            # Add to history for lightweight context (simple concatenation)
            history.append(("user", user_in))

            prompt_text = "\n".join([f"{role}: {msg}" for role, msg in history])
            result = await ai.generate(prompt=prompt_text, system=sys_prompt)
            reply = (
                result.output
                if isinstance(result.output, str)
                else json.dumps(result.output, ensure_ascii=False)
            )

            history.append(("assistant", reply))
            click.echo(click.style(f"ai> {reply}", fg="magenta"))

    asyncio.run(run())


if __name__ == "__main__":
    cli()
