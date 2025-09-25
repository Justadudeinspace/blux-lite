# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: libf-save

Saves a "context window session" (stdin or file) into a Liberation Framework
project's history as JSONL. Paths are aligned to the installer (~/.blux-lite).

Usage:
  some_command | blux libf-save <project> --title "My session"
  blux libf-save <project> --title "My session" --file ./session.txt
"""
import sys
import json
from pathlib import Path
import click
from blux.settings import SETTINGS
from blux.memory import save_memory


def _read_text_from_stdin() -> str:
    if sys.stdin and not sys.stdin.isatty():
        return sys.stdin.read()
    return ""


@click.command("libf-save")
@click.argument("project", type=str)
@click.option("--title", type=str, required=False, help="Optional session title")
@click.option(
    "--file",
    "file_",
    type=click.Path(exists=True, dir_okay=False),
    required=False,
    help="Read session text from file",
)
def libf_save(project: str, title: str | None, file_: str | None):
    """
    Save a whole "context window session" (any text you pipe in or pass via a file)
    into a chosen project's Liberation Framework history under:
      $HOME/.blux-lite/libf/projects/<project>/history/*.jsonl
    """
    # Decide body source
    body = ""
    if file_:
        body = Path(file_).read_text(encoding="utf-8", errors="ignore")
    else:
        body = _read_text_from_stdin()
    if not body.strip():
        raise click.ClickException(
            "No input text. Pipe text into the command or use --file."
        )

    # Title fallback
    if not title:
        title = "Session"

    # Ensure projects dir matches installer convention: ~/.blux-lite/libf/projects
    proj_dir = Path(
        str(
            SETTINGS.get(
                "libf_projects_dir", Path.home() / ".blux-lite" / "libf" / "projects"
            )
        )
    )

    # Apply save
    save_memory(project, title, body)

    # Also show where it landed for convenience
    hist = proj_dir.expanduser() / project / "history"
    click.echo(f"Saved session to project '{project}'. History dir: {hist}")


def register(cli):
    # Attach as a subcommand of the root CLI
    cli.add_command(libf_save)
