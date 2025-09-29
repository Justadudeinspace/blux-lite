# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: project
Commands:
  blux project show
  blux project set <name>
  blux project sessions [--last N]
"""
import click
from blux.settings import load_settings, save_settings, SETTINGS
from blux.memory import list_sessions, libf_path


def register(cli):
    @cli.group(name="project")
    def group():
        """Project helpers."""
        pass

    @group.command("show")
    def show_cmd():
        cfg = dict(SETTINGS)
        proj = cfg.get("project", "default")
        click.echo(f"Project     : {proj}")
        click.echo(f"Memory file : {libf_path(proj)}")

    @group.command("set")
    @click.argument("name", required=True)
    def set_cmd(name):
        cfg = load_settings()
        cfg["project"] = name
        save_settings(cfg)
        click.echo(f"Project set → {name}")

    @group.command("sessions")
    @click.option("--last", "last_n", type=int, default=10, help="Show last N entries")
    def sessions_cmd(last_n):
        proj = str(SETTINGS.get("project", "default"))
        entries = list_sessions(proj)
        for row in entries[-last_n:]:
            click.echo(f"{row.get('ts','?')}  |  {row.get('prompt','')[:48]}")
