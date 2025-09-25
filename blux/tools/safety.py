from __future__ import annotations
from pathlib import Path
from typing import List

ROOT = Path(__file__).resolve().parent.parent.parent

SAFE_WRITE_PREFIXES: List[Path] = [
    ROOT / "uploads",
    ROOT / "scripts",
    ROOT / "plugins" / "liberation_framework",
    ROOT / ".config" / "blux-lite-gold",
    ROOT / "docs",
]


def normalize(p: str | Path) -> Path:
    q = Path(p).expanduser().resolve()
    return q


def is_safe_path(p: str | Path) -> bool:
    q = normalize(p)
    try:
        q.relative_to(ROOT)
    except ValueError:
        return False
    for prefix in SAFE_WRITE_PREFIXES:
        try:
            q.relative_to(prefix.resolve())
            return True
        except ValueError:
            continue
    return False
