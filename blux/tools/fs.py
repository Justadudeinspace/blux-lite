from __future__ import annotations
from pathlib import Path
from typing import Optional


def ls(path: str = ".") -> str:
    p = Path(path).expanduser()
    if not p.exists():
        return f"[ERR] not found: {p}"
    items = []
    for x in sorted(p.iterdir(), key=lambda x: (x.is_file(), x.name.lower())):
        mark = "/" if x.is_dir() else ""
        items.append(x.name + mark)
    return "\n".join(items)


def read(path: str) -> str:
    p = Path(path).expanduser()
    if not p.exists():
        return f"[ERR] not found: {p}"
    try:
        return p.read_text(encoding="utf-8")
    except Exception:
        return p.read_bytes().hex()


def write(path: str, content: str) -> str:
    p = Path(path).expanduser()
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    return f"[OK] wrote {p} ({len(content)} bytes)"
