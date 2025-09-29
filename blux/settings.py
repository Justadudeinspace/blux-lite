# -*- coding: utf-8 -*-
"""BLUX Lite Gold settings — repo-local, with separate libf config dir.
- Core config:   ./.config/blux-lite-gold/
- libf config:   ./.config/libf/
- Projects dir:  ./libf/projects/
"""
from __future__ import annotations
import os, json, threading
from pathlib import Path
from typing import Dict, Any

_DEFAULT_ROOT = Path(__file__).resolve().parent.parent
ROOT = Path(os.getenv("BLUX_ROOT", str(_DEFAULT_ROOT))).resolve()

CONFIG_DIR = Path(
    os.getenv("BLUX_CONFIG_DIR", str(ROOT / ".config" / "blux-lite-gold"))
).resolve()
LIBF_CONFIG_DIR = Path(
    os.getenv("BLUX_LIBF_CONFIG_DIR", str(ROOT / ".config" / "libf"))
).resolve()
LIBF_PROJECTS_DIR = Path(
    os.getenv("BLUX_LIBF_PROJECTS_DIR", str(ROOT / "libf" / "projects"))
).resolve()

for p in (CONFIG_DIR, LIBF_CONFIG_DIR, LIBF_PROJECTS_DIR):
    p.mkdir(parents=True, exist_ok=True)

DEFAULTS: Dict[str, Any] = {
    "edition": "PERSONAL",
    "version": "dev",
    "config_dir": str(CONFIG_DIR),
    "libf_config_dir": str(LIBF_CONFIG_DIR),
    "libf_projects_dir": str(LIBF_PROJECTS_DIR),
    "log_file": str(CONFIG_DIR / "blux_lite.log"),
    "project": os.getenv("BLUX_PROJECT", "default"),
    "ui": {"theme": "auto"},
}

_lock = threading.Lock()


def _ensure_dirs(s: Dict[str, Any]) -> None:
    for k in ("config_dir", "libf_config_dir", "libf_projects_dir"):
        Path(str(s[k])).mkdir(parents=True, exist_ok=True)
    # ensure logs exist
    Path(str(s.get("log_file", Path(CONFIG_DIR / "blux_lite.log")))).touch(
        exist_ok=True
    )


def save_settings(s: Dict[str, Any]) -> None:
    path = CONFIG_DIR / "settings.json"
    with _lock:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(s, ensure_ascii=False, indent=2), encoding="utf-8")


def load_settings() -> Dict[str, Any]:
    path = CONFIG_DIR / "settings.json"
    if path.exists():
        try:
            s = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            s = DEFAULTS.copy()
    else:
        s = DEFAULTS.copy()
    for k, v in DEFAULTS.items():
        s.setdefault(k, v)
    _ensure_dirs(s)
    return s


SETTINGS = load_settings()
