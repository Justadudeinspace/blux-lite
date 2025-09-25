# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: router
Command:
  blux router test "<prompt...>"
Shows which intent the router picks for a prompt.
"""
import click
from blux.router import detect_intent, sanitize_prompt


def register(cli):
    @cli.group(name="router")
    def group():
        """Router introspection."""
        pass

    @group.command("test")
    @click.argument("prompt", nargs=-1, required=True)
    def test_cmd(prompt):
        p = sanitize_prompt(" ".join(prompt))
        intent = detect_intent(p)
        click.echo(f"Intent: {intent}")
