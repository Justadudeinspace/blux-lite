# -*- coding: utf-8 -*-
"""
Plugin Template for BLUX Lite

Copy this file to: plugins/<your-plugin>.py
Rename functions/groups and fill in your logic.
The loader will import any *.py in plugins/ and call register(cli).
"""
import click


def register(cli):
    @cli.group(name="myplug")
    def myplug():
        """One-line description of your plugin."""
        pass

    @myplug.command("hello")
    @click.option("--name", default="world")
    def hello(name):
        """Example subcommand: prints a greeting."""
        click.echo(f"Hello, {name}! (from myplug)")

    @myplug.command("do")
    @click.argument("thing", nargs=-1, required=True)
    def do(thing):
        """Example with args: echoes what you'll do."""
        click.echo("Doing: " + " ".join(thing))
