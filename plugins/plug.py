# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: plug

Browse, inspect, and interact with installed plugins in /plugins.

Commands:
  blux plug list                 # non-interactive list with summaries
  blux plug info <name|index>    # show detailed info for one plugin
  blux plug open <name|index>    # open plugin file in $EDITOR or system opener
  blux plug menu                 # interactive menu (list/search/view/open)

Details auto-extracted from each plugin's Python file:
- title/summary from top-level module docstring (first paragraph)
- commands via regex: @cli.group(name="..."), @cli.command(name="..."), @<group>.command("...")
- file name, size, last modified time

Tips for authors: include a nice module docstring and usage examples with fenced code blocks.
"""
import os, re, sys, textwrap, shutil, datetime, subprocess
from dataclasses import dataclass, asdict
from typing import List, Optional, Tuple
from pathlib import Path
import click

from blux.plugins import PLUGINS_DIR  # same constant used by loader

GROUP_NAME = "plug"

# ----------- extraction helpers -----------


@dataclass
class PluginInfo:
    name: str
    path: Path
    title: str
    summary: str
    commands: List[str]
    size_kb: float
    mtime: str


DOCSTRING_RE = re.compile(r'^\s*(?:[ruRU]{0,2}["\']{3})(.*?)(?:["\']{3})', re.S)
CLI_GROUP_RE = re.compile(r'@cli\.group\s*\(\s*name\s*=\s*["\']([^"\']+)["\']', re.S)
CLI_CMD_RE = re.compile(r'@cli\.command\s*\(\s*name\s*=\s*["\']([^"\']+)["\']', re.S)
SUBCMD_RE = re.compile(
    r'@([A-Za-z_][A-Za-z0-9_]*)\.command\s*\(\s*["\']([^"\']+)["\']', re.S
)


def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="ignore")


def _doc_from_source(src: str) -> Tuple[str, str]:
    m = DOCSTRING_RE.search(src)
    if not m:
        return "", ""
    raw = m.group(1).strip()
    # Title = first non-empty line; Summary = first paragraph
    lines = [ln.rstrip() for ln in raw.splitlines()]
    title_line = next((ln for ln in lines if ln.strip()), "")
    paras = [p.strip() for p in raw.split("\n\n") if p.strip()]
    summary = paras[0] if paras else title_line
    return title_line, summary


def _commands_from_source(src: str) -> List[str]:
    cmds = set()
    for m in CLI_GROUP_RE.finditer(src):
        cmds.add(m.group(1))
    for m in CLI_CMD_RE.finditer(src):
        cmds.add(m.group(1))
    for m in SUBCMD_RE.finditer(src):
        grp, sub = m.group(1), m.group(2)
        cmds.add(f"{grp} {sub}")
    return sorted(cmds)


def _fmt_mtime(ts: float) -> str:
    return datetime.datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M:%S")


def scan_plugins() -> List[PluginInfo]:
    out: List[PluginInfo] = []
    PLUGINS_DIR.mkdir(parents=True, exist_ok=True)
    for py in sorted(PLUGINS_DIR.glob("*.py")):
        if py.name.startswith("_"):  # skip templates/hidden helpers
            continue
        try:
            src = _read(py)
            title_line, summary = _doc_from_source(src)
            title = title_line or f"Plugin {py.stem}"
            commands = _commands_from_source(src)
            stat = py.stat()
            out.append(
                PluginInfo(
                    name=py.stem,
                    path=py,
                    title=title,
                    summary=summary,
                    commands=commands,
                    size_kb=round(stat.st_size / 1024.0, 1),
                    mtime=_fmt_mtime(stat.st_mtime),
                )
            )
        except Exception as e:
            out.append(
                PluginInfo(
                    name=py.stem,
                    path=py,
                    title=f"Plugin {py.stem}",
                    summary=f"(failed to parse: {e})",
                    commands=[],
                    size_kb=0.0,
                    mtime="",
                )
            )
    return out


def _match_plugin(items: List[PluginInfo], key: str) -> PluginInfo:
    if key.isdigit():
        idx = int(key) - 1
        if 0 <= idx < len(items):
            return items[idx]
        raise click.ClickException("Index out of range.")
    # name exact / prefix
    for it in items:
        if it.name == key or it.name.startswith(key):
            return it
    raise click.ClickException(f"No plugin matched: {key}")


def _open_file(path: Path):
    editor = os.getenv("EDITOR")
    if editor and shutil.which(editor):
        subprocess.call([editor, str(path)])
        return
    if shutil.which("termux-open"):
        subprocess.call(["termux-open", str(path)])
    elif shutil.which("xdg-open"):
        subprocess.call(["xdg-open", str(path)])
    elif shutil.which("open"):
        subprocess.call(["open", str(path)])
    else:
        click.echo(str(path))


# ----------- CLI -----------


def register(cli):
    @cli.group(name=GROUP_NAME)
    def group():
        """Interactive explorer for installed plugins."""
        pass

    @group.command("list")
    @click.option(
        "--long", "long_", is_flag=True, help="Show full summaries and commands"
    )
    def list_cmd(long_):
        """List plugins with brief or detailed info."""
        items = scan_plugins()
        if not items:
            click.echo("(no plugins found)")
            return
        for i, it in enumerate(items, 1):
            click.echo(f"{i:>2}. {it.name}  {it.size_kb:>6.1f}KB  {it.mtime}")
            click.echo(f"    {it.title}")
            if long_:
                if it.summary and it.summary != it.title:
                    click.echo("    " + it.summary.replace("\n", "\n    "))
                if it.commands:
                    click.echo("    commands: " + ", ".join(it.commands))
            else:
                if it.commands:
                    click.echo(
                        "    cmds: "
                        + ", ".join(it.commands[:6])
                        + (" ..." if len(it.commands) > 6 else "")
                    )
        click.echo(f"\nTotal: {len(items)} plugin(s) @ {PLUGINS_DIR}")

    @group.command("info")
    @click.argument("key")
    def info_cmd(key):
        """Show detailed information for one plugin (by name or index)."""
        items = scan_plugins()
        it = _match_plugin(items, key)
        click.echo(f"name    : {it.name}")
        click.echo(f"title   : {it.title}")
        click.echo(f"path    : {it.path}")
        click.echo(f"updated : {it.mtime}")
        click.echo(f"size    : {it.size_kb} KB")
        if it.summary:
            click.echo("\nsummary :")
            click.echo(textwrap.indent(it.summary, "  "))
        if it.commands:
            click.echo("\ncommands:")
            for c in it.commands:
                click.echo(f"  - {c}")

    @group.command("open")
    @click.argument("key")
    def open_cmd(key):
        """Open a plugin file in $EDITOR or the system opener."""
        items = scan_plugins()
        it = _match_plugin(items, key)
        _open_file(it.path)

    @group.command("menu")
    def menu_cmd():
        """Interactive menu for browsing plugins."""
        items = scan_plugins()
        if not items:
            click.echo("(no plugins found)")
            return
        sel = 0
        while True:
            os.system("clear" if os.name != "nt" else "cls")
            click.echo(
                "BLUX Plugins — interactive menu (q=quit, i=open info, o=open file, j/k=down/up, r=refresh)"
            )
            click.echo(f"Root: {PLUGINS_DIR}\n")
            for i, it in enumerate(items, 1):
                marker = "➤" if (i - 1) == sel else " "
                title = (it.title[:80] + "…") if len(it.title) > 80 else it.title
                click.echo(
                    f"{marker} {i:>2}. {it.name:16}  {it.size_kb:>6.1f}KB  {it.mtime}  | {title}"
                )
            click.echo("\nCommand: ", nl=False)
            sys.stdout.flush()
            try:
                cmd = sys.stdin.readline().strip()
            except KeyboardInterrupt:
                cmd = "q"
            if cmd in ("q", "quit", "exit"):
                break
            elif cmd in ("j", "down"):
                sel = min(sel + 1, len(items) - 1)
            elif cmd in ("k", "up"):
                sel = max(sel - 1, 0)
            elif cmd in ("r", "refresh"):
                items = scan_plugins()
                sel = min(sel, len(items) - 1)
            elif cmd in ("i", "info"):
                os.system("clear" if os.name != "nt" else "cls")
                it = items[sel]
                click.echo(f"[{sel+1}] {it.name}\n")
                click.echo(f"path    : {it.path}")
                click.echo(f"updated : {it.mtime}")
                click.echo(f"size    : {it.size_kb} KB\n")
                click.echo(
                    "summary:\n" + textwrap.indent(it.summary or "(no docstring)", "  ")
                )
                if it.commands:
                    click.echo("\ncommands:")
                    for c in it.commands:
                        click.echo(f"  - {c}")
                click.echo("\n[enter to return]")
                sys.stdin.readline()
            elif cmd in ("o", "open"):
                it = items[sel]
                _open_file(it.path)
            elif cmd.isdigit():
                n = int(cmd)
                if 1 <= n <= len(items):
                    sel = n - 1
            else:
                # allow 'info 3' / 'open 2'
                parts = cmd.split()
                if len(parts) == 2 and parts[0] in ("info", "open"):
                    it = _match_plugin(items, parts[1])
                    if parts[0] == "info":
                        os.system("clear" if os.name != "nt" else "cls")
                        click.echo(
                            f"{it.name}\n\npath: {it.path}\nupdated: {it.mtime}\nsize: {it.size_kb} KB\n"
                        )
                        click.echo(
                            "summary:\n"
                            + textwrap.indent(it.summary or "(no docstring)", "  ")
                        )
                        if it.commands:
                            click.echo("\ncommands:")
                            for c in it.commands:
                                click.echo(f"  - {c}")
                        click.echo("\n[enter to return]")
                        sys.stdin.readline()
                    else:
                        _open_file(it.path)
