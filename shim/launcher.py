# -*- coding: utf-8 -*-
#!/usr/bin/env python3
"""Thin shim used as console_scripts entry to launch BLUX CLI without import cycles."""
from __future__ import annotations
import sys
from pathlib import Path
import runpy


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    pkg_cli = root / "blux" / "cli.py"
    root_blux = root / "blux.py"

    if str(root) not in sys.path:
        sys.path.insert(0, str(root))

    # Prefer the package CLI, but run by path to avoid circular imports
    if pkg_cli.exists():
        runpy.run_path(str(pkg_cli), run_name="__main__")
        return

    # Fallback to root orchestrator
    if root_blux.exists():
        runpy.run_path(str(root_blux), run_name="__main__")
        return

    print("Error: No CLI found (blux/cli.py or blux.py)", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
