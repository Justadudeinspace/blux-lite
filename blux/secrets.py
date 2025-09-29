# blux/secrets.py
# -*- coding: utf-8 -*-
"""
secrets.py — Lazy env loader for BLUX Lite GOLD.

Loads variables from, in order of precedence:
1) "./.secrets/secrets.env" (project-local)
2) "/.secrets/secrets.env"  (system-level / Termux)

Duplicates do not overwrite existing process env unless overwrite=True.
"""
from __future__ import annotations
import os
from pathlib import Path
from typing import Optional

PROJECT_LOCAL = Path("./.secrets/secrets.env").resolve()
SYSTEM_LEVEL = Path("/.secrets/secrets.env")

_LOADED = False


def _parse_env_file(path: Path) -> dict:
    data = {}
    if not path.exists():
        return data
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            k, v = line.split("=", 1)
            data[k.strip()] = v.strip()
    return data


def load_env(overwrite: bool = False) -> None:
    """Load env into os.environ. Set overwrite=True to replace existing."""
    global _LOADED
    merged = {}
    # precedence: project-local first, then system-level (only if keys missing)
    for src in (PROJECT_LOCAL, SYSTEM_LEVEL):
        merged.update(
            {k: v for k, v in _parse_env_file(src).items() if k not in merged}
        )
    for k, v in merged.items():
        if overwrite or k not in os.environ:
            os.environ[k] = v
    _LOADED = True


def get(key: str, default: Optional[str] = None) -> Optional[str]:
    if not _LOADED:
        load_env(overwrite=False)
    return os.environ.get(key, default)
