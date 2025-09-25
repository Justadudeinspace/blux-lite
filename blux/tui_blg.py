# blux/tui_blg.py — route TUI to your shell menu until Textual app is wired
from __future__ import annotations
import os, subprocess, sys


def main() -> int:
    try:
        import textual  # noqa: F401

        project_root = os.path.dirname(os.path.dirname(__file__))
        shell_tui = os.path.join(project_root, "scripts", "tui", "menu.sh")
        if os.path.isfile(shell_tui):
            return subprocess.call([shell_tui])
        legacy = os.path.join(project_root, "scripts_menu.sh")
        if os.path.isfile(legacy):
            return subprocess.call([legacy])
        print("BLUX TUI entry not found.")
        return 1
    except Exception:
        project_root = os.path.dirname(os.path.dirname(__file__))
        legacy = os.path.join(project_root, "scripts_menu.sh")
        if os.path.isfile(legacy):
            return subprocess.call([legacy])
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
