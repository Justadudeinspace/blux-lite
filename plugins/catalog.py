# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: catalog
Commands:
  blux catalog list
  blux catalog search <term>
  blux catalog download <id...>
"""
import re, click
from pathlib import Path
from blux.models import MODEL_CATALOG, hf_download
from blux.settings import SETTINGS


def _match(term, text):
    t = term.lower()
    x = text.lower()
    return t in x or all(part in x for part in t.split())


def register(cli):
    @cli.group(name="catalog")
    def group():
        """Model catalog helpers."""
        pass

    @group.command("list")
    @click.option(
        "--filter",
        "kind",
        type=click.Choice(["coding", "general", "all"]),
        default="all",
        help="Filter by kind",
    )
    def list_cmd(kind):
        items = sorted(MODEL_CATALOG.items())
        if not items:
            click.echo("(empty catalog)")
            return
        for k, v in items:
            if (
                kind != "all"
                and v.get("type", "?") != kind
                and v.get("category", v.get("cat", "")) != kind
            ):
                continue
            kind = v.get("type", "?")
            repo = v.get("repo", "(ollama/openai)")
            inc = v.get("include", "")
            click.echo(f"{k:18}  {kind:6}  {repo}  {inc}")

    @group.command("search")
    @click.argument("term", nargs=-1, required=True)
    def search_cmd(term):
        q = " ".join(term).strip()
        for k, v in MODEL_CATALOG.items():
            blob = f"{k} {v.get('repo','')} {v.get('include','')}"
            if _match(q, blob):
                click.echo(k)

    @group.command("download")
    @click.argument("ids", nargs=-1, required=True)
    def dl_cmd(ids):
        dest = Path(str(SETTINGS.get("models_dir"))).expanduser()
        dest.mkdir(parents=True, exist_ok=True)
        for mid in ids:
            meta = MODEL_CATALOG.get(mid)
            if not meta or meta.get("type") != "gguf":
                click.echo(f"Skip {mid}: not a GGUF catalog ID")
                continue
            repo = meta["repo"]
            include = meta.get("include", "*.gguf")
            ok = hf_download(repo, include, dest)
            click.echo(f"{'OK' if ok else 'FAIL'}: {mid} -> {dest}")
