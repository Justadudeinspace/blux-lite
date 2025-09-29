from __future__ import annotations
from textwrap import dedent


def plugin_skeleton(slug: str, title: str | None = None) -> str:
    title = title or slug.replace("_", " ").title()
    return dedent(
        f'''
# -*- coding: utf-8 -*-
"""BLUX .libf Plugin — {title}
path: plugins/liberation_framework/{slug}.py
"""
import click

def register(app):
    @app.command("{slug}")
    @click.option("--echo", is_flag=True, help="echo hello from {title}")
    def {slug}(echo: bool):
        """{title} — sample plugin command."""
        if echo:
            click.echo("Hello from {title}!")
        else:
            click.echo("{title} ready.")
'''
    )
