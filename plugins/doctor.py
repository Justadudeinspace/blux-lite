# -*- coding: utf-8 -*-
"""BLUX Lite GOLD plugin for system diagnostics."""
from __future__ import annotations
import os
import shutil
import click


def _which(cmd: str) -> bool:
    return shutil.which(cmd) is not None


def register(cli: click.Group) -> None:
    @cli.command()
    def doctor() -> None:
        """Run a series of checks to diagnose potential issues."""
        checks = {
            "ollama": {
                "name": "Ollama (local model engine)",
                "ok": _which("ollama"),
                "fix": "Install ollama from https://ollama.ai/",
            },
            "openai_api_key": {
                "name": "OpenAI API Key (for GPT models)",
                "ok": bool(os.environ.get("OPENAI_API_KEY")),
                "fix": "Set the OPENAI_API_KEY environment variable.",
            },
        }

        click.secho("BLUX Lite GOLD Doctor", fg="cyan", bold=True)
        all_ok = True
        for check_id, check in checks.items():
            status = "OK" if check["ok"] else "FAIL"
            color = "green" if check["ok"] else "red"
            click.secho(f"- {check['name']}: ", nl=False)
            click.secho(status, fg=color, bold=True)
            if not check["ok"]:
                all_ok = False
                click.echo(f"  - Fix: {check['fix']}")

        if all_ok:
            click.secho("\nAll checks passed!", fg="green", bold=True)
        else:
            click.secho(
                "\nSome checks failed. Please review the messages above.", fg="yellow"
            )
