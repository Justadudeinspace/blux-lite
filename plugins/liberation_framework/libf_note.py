# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: libf-note
Command:
  blux libf-note "<short-title>" --text "longer details..."
Stores a note into the project's .libf history as a memory entry.
"""
import click
from blux.settings import SETTINGS
from blux.memory import save_memory


def register(cli):
    @cli.command(name="libf-note")
    @click.argument("title", required=True)
    @click.option("--text", default="", help="Optional longer note text")
    def libf_note(title, text):
        proj = str(SETTINGS.get("project", "default"))
        prompt = f"NOTE: {title}"
        answer = text or "(empty note)"
        save_memory(proj, prompt, answer)
        click.echo(f"Saved .libf note to project '{proj}'")
