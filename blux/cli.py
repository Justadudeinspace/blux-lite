# blux/cli.py
from __future__ import annotations
import sys

import subprocess
from typing import List
import typer

app = typer.Typer(no_args_is_help=True, add_completion=False)


def _run_tui() -> int:
    try:
        import textual  # noqa: F401
        from .tui_blg import main as tui_main

        return int(tui_main() or 0)
    except Exception:
        from .legacy_menu import main as legacy_main

        return int(legacy_main() or 0)


def _run_legacy() -> int:
    from .legacy_menu import main as legacy_main

    return int(legacy_main() or 0)


@app.command(help="Start BLUX Lite GOLD (auto-select UI or force TUI/legacy).")
def start(
    mode: str = typer.Option(
        "auto", "--mode", "-m", help="UI mode: auto|tui|legacy (default: auto)"
    ),
    rest: List[str] = typer.Argument(
        None
    ),  # ACCEPT & IGNORE extra legacy args like 'prompt'
) -> None:
    """
    Examples:
      python -m blux.cli start
      python -m blux.cli start --mode tui
      python -m blux.cli start --mode legacy
      # legacy compatibility:
      python -m blux.cli start prompt
      python -m blux.cli start menu
      python -m blux.cli start legacy-menu
    """
    # Map legacy positionals if present (e.g., 'prompt', 'menu', 'legacy-menu')
    legacy_map = {
        "prompt": "tui",
        "menu": "tui",
        "tui_blg": "tui",
        "legacy-menu": "legacy",
        "legacy": "legacy",
    }
    # If the user passed a positional first, prefer it over --mode
    if rest:
        candidate = rest[0].strip().lower()
        mode = legacy_map.get(candidate, mode)

    mode = (mode or "auto").strip().lower()
    if mode in ("tui", "menu", "tui_blg", ""):
        rc = _run_tui()
    elif mode == "legacy":
        rc = _run_legacy()
    elif mode == "auto":
        rc = _run_tui()  # try Textual, then fallback to legacy inside _run_tui()
    else:
        typer.secho(f"Unknown mode: {mode}", fg=typer.colors.RED, err=True)
        raise typer.Exit(code=2)

    raise typer.Exit(code=rc)


if __name__ == "__main__":
    app()


@app.command("shell")
def shell(
    mode: str = typer.Option(
        "interactive",
        help="Run integrated shell; pass 'interactive' or a command string",
    ),
    cmd: str = typer.Argument(None, help="Optional command to run non-interactively"),
):
    """Run the BLUX integrated shell, either in interactive mode or by passing a command.

    Args:
        mode: The mode to run the shell in. Can be 'interactive' or a command string.
        cmd: The command to run non-interactively.
    """
    from .ish import main as ish_main

    if mode != "interactive" and cmd:
        raise typer.Exit(code=subprocess.run(cmd, shell=True, check=True).returncode)
    raise typer.Exit(code=ish_main([] if mode == "interactive" else [cmd]))
