from __future__ import annotations
import subprocess


def status() -> str:
    try:
        out = subprocess.check_output(
            ["git", "status", "--short", "--branch"], text=True
        )
        return out
    except Exception as e:
        return f"[ERR] git status: {e}"


def diff(pathspec: str = "") -> str:
    try:
        cmd = ["git", "diff"]
        if pathspec:
            cmd.append(pathspec)
        out = subprocess.check_output(cmd, text=True)
        return out
    except Exception as e:
        return f"[ERR] git diff: {e}"
