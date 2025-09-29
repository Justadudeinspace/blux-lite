# -*- coding: utf-8 -*-
#!/usr/bin/env python3
"""
Root-level BLUX shiv/CLI orchestrator.

- Delegates to the package CLI in ``blux/cli.py`` when available.
- Provides a minimal, dependency-light fallback so basic actions still work.
- Tolerant of legacy positionals like `start prompt` / `menu` / `legacy`.
- Avoids heavy imports at module import time.
"""

from __future__ import annotations

import os
import sys
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
PKG_DIR = HERE / "blux"
SCRIPTS_DIR = HERE / "scripts"


# ------------------------ small helpers ------------------------
def _echo(s: str, err: bool = False) -> None:
    (sys.stderr if err else sys.stdout).write(s + "\n")


def _run(cmd: list[str]) -> int:
    try:
        return subprocess.call(cmd, env=os.environ.copy())
    except Exception as e:
        _echo(f"[ERR] failed to run {cmd!r}: {e}", err=True)
        return 127


def _load_env() -> None:
    """Load basic secrets env files if present (non-fatal)."""
    # Project-local secrets
    for p in (
        HERE / ".secrets" / "secrets.env",
        HERE / ".config" / "blux-lite" / ".env",
    ):
        if p.exists():
            try:
                for line in p.read_text(encoding="utf-8").splitlines():
                    if not line or line.strip().startswith(("#", ";")):
                        continue
                    if "=" in line:
                        k, v = line.split("=", 1)
                        os.environ.setdefault(k.strip(), v.strip())
            except Exception as e:
                _echo(f"[WARN] secrets load failed: {e}", err=True)


def _map_legacy_mode(mode: str | None, rest: list[str] | None) -> str:
    """Map legacy tokens to canonical modes (tui/legacy/auto)."""
    m = (mode or "auto").strip().lower()
    legacy_map = {
        "": "auto",
        "prompt": "tui",
        "menu": "tui",
        "tui_blg": "tui",
        "legacy-menu": "legacy",
        "legacy": "legacy",
    }
    # If user passed a positional after start (e.g., `start prompt`)
    if rest:
        cand = (rest[0] or "").strip().lower()
        m = legacy_map.get(cand, m)
    return m


# ------------------ dynamic load of package CLI ------------------
_click_app = None  # click.Command from blux/cli.py via Typer bridge


def _load_pkg_cli() -> None:
    """Import blux/cli.py dynamically and extract its Typer app as a click.Command."""
    global _click_app
    try:
        cli_path = PKG_DIR / "cli.py"
        if not cli_path.exists():
            return
        import importlib.util

        spec = importlib.util.spec_from_file_location("blux.cli", str(cli_path))
        if not spec or not spec.loader:
            return
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[attr-defined]
        if hasattr(mod, "app"):
            # Typer→click bridge done at call-time to avoid importing click/typer unless needed
            from typer.main import get_command

            _click_app = get_command(mod.app)  # click.Command
    except Exception as e:
        _echo(f"[INFO] Could not load blux/cli.py: {e}", err=True)


# --------------------- click shim (fallback) ---------------------
def _click_fallback():
    """Return a click.Command (shim or merged with real app) or None if click missing."""
    try:
        import click
    except Exception:
        return None

    @click.group(
        help="BLUX shim CLI (fallback). Real CLI loads from blux/cli.py if present."
    )
    def shim() -> None: ...

    @shim.command("version")
    def version() -> None:
        v = os.environ.get("BLUX_VERSION", "local-dev")
        click.echo(f"BLUX Lite GOLD: {v}")

    @shim.command("start")
    @click.option("--mode", "-m", default="auto", help="UI mode: auto|tui|legacy")
    @click.argument("rest", nargs=-1)
    def start(mode: str, rest: tuple[str, ...]) -> None:
        """Start the program (tui/legacy). Fallback runner when package CLI is unavailable."""
        m = _map_legacy_mode(mode, list(rest))
        if m in ("tui", "auto"):
            # Prefer direct module run (lets blux.tui_blg decide fallback)
            sys.exit(_run([sys.executable, "-m", "blux.tui_blg", *rest]))
        # Legacy: prefer shell legacy menu if present; otherwise route to package CLI if it exists later
        scripts_menu = SCRIPTS_DIR / "scripts_menu.sh"
        if scripts_menu.exists():
            sys.exit(_run(["bash", str(scripts_menu)]))
        # Last resort: inform user
        click.echo(
            "[WARN] legacy menu not found; install/launch via `auto-start.sh` or `python -m blux.cli`."
        )

    @shim.command("doctor")
    def doctor() -> None:
        click.echo("BLUX doctor: OK")

    # If we loaded the package CLI, merge both into one command collection
    if _click_app is not None:
        return click.CommandCollection(sources=[shim, _click_app], help="BLUX CLI")
    return shim


# --------------------------- main ---------------------------
def main(argv: list[str] | None = None) -> None:
    _load_env()
    _load_pkg_cli()

    args = list(sys.argv[1:] if argv is None else argv)

    # If we have click (and optionally the pkg CLI), use that path
    cli = _click_fallback()
    if cli is not None:
        try:
            # Let click handle parsing, including legacy args via our shim
            cli(standalone_mode=True, prog_name="blux", args=args)  # type: ignore[call-arg]
            return
        except SystemExit:
            raise
        except Exception as e:
            _echo(f"[WARN] click CLI failed: {e}", err=True)

    # -------- argparse zero-dep fallback (no click available) --------
    import argparse

    p = argparse.ArgumentParser(
        prog="blux", description="BLUX shim CLI (argparse fallback)"
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    sp_start = sub.add_parser("start", help="Start UI")
    sp_start.add_argument(
        "--mode", "-m", default="auto", help="UI mode: auto|tui|legacy"
    )
    sp_start.add_argument("rest", nargs="*")

    sub.add_parser("version", help="Show version")
    sub.add_parser("doctor", help="Doctor check")

    ns = p.parse_args(args)

    if ns.cmd == "version":
        print(os.environ.get("BLUX_VERSION", "local-dev"))
        return

    if ns.cmd == "doctor":
        print("BLUX doctor: OK")
        return

    if ns.cmd == "start":
        m = _map_legacy_mode(ns.mode, ns.rest)
        if m in ("tui", "auto"):
            sys.exit(_run([sys.executable, "-m", "blux.tui_blg", *ns.rest]))
        scripts_menu = SCRIPTS_DIR / "scripts_menu.sh"
        if scripts_menu.exists():
            sys.exit(_run(["bash", str(scripts_menu)]))
        print(
            "[WARN] legacy menu not found; use `./auto-start.sh` or `python -m blux.cli`."
        )
        return


if __name__ == "__main__":
    main()
