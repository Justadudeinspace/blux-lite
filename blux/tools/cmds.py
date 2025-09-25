from __future__ import annotations
import json, subprocess, shlex
from pathlib import Path
from typing import List, Tuple
from .registry import load_plan, save_plan


def add_cmd(command: str) -> None:
    p = load_plan()
    p.setdefault("actions", []).append({"type": "run_cmd", "command": command})
    save_plan(p)


def list_cmds() -> List[str]:
    p = load_plan()
    return [
        a.get("command", "") for a in p.get("actions", []) if a.get("type") == "run_cmd"
    ]


def apply_cmds() -> List[Tuple[str, int]]:
    p = load_plan()
    out: List[Tuple[str, int]] = []
    remaining = []
    for a in p.get("actions", []):
        if a.get("type") == "run_cmd":
            cmd = a.get("command", "")
            try:
                rc = subprocess.call(cmd, shell=True)
            except Exception:
                rc = 1
            out.append((cmd, rc))
        else:
            remaining.append(a)
    p["actions"] = remaining
    save_plan(p)
    return out
