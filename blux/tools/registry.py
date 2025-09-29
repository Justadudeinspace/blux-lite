from __future__ import annotations
import json
from pathlib import Path
from .safety import is_safe_path
from typing import List, Dict, Any, Tuple

ROOT = Path(__file__).resolve().parent.parent.parent
CONFIG_DIR = ROOT / ".config" / "blux-lite-gold"
TOOLS_DIR = CONFIG_DIR / "tools"
PLAN_PATH = TOOLS_DIR / "plan.json"


def _ensure():
    TOOLS_DIR.mkdir(parents=True, exist_ok=True)
    if not PLAN_PATH.exists():
        PLAN_PATH.write_text(json.dumps({"actions": []}, indent=2), encoding="utf-8")


def load_plan() -> Dict[str, Any]:
    _ensure()
    try:
        return json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {"actions": []}


def save_plan(plan: Dict[str, Any]) -> None:
    _ensure()
    PLAN_PATH.write_text(json.dumps(plan, indent=2), encoding="utf-8")


def clear_plan() -> None:
    save_plan({"actions": []})


def add_action(action: Dict[str, Any]) -> None:
    p = load_plan()
    p.setdefault("actions", []).append(action)
    save_plan(p)


def show_plan() -> str:
    p = load_plan()
    lines = []
    for i, a in enumerate(p.get("actions", []), 1):
        kind = a.get("type", "?")
        if kind in ("write_file", "append_file"):
            lines.append(
                f"{i}. {kind} {a.get('path')} ({len(a.get('content',''))} bytes)"
            )
        elif kind == "replace_in_file":
            lines.append(
                f"{i}. {kind} {a.get('path')} FROM[{a.get('before','')[:20]}...] TO[{a.get('after','')[:20]}...]"
            )
        else:
            lines.append(f"{i}. {kind} {a}")
    return "\n".join(lines) if lines else "(no actions)"


def apply_plan() -> List[Tuple[str, str]]:
    p = load_plan()
    results: List[Tuple[str, str]] = []
    for a in p.get("actions", []):
        t = a.get("type")
        if t == "write_file":
            results.append(_write_file(a.get("path", ""), a.get("content", "")))
        elif t == "append_file":
            results.append(_append_file(a.get("path", ""), a.get("content", "")))
        elif t == "replace_in_file":
            results.append(
                _replace_in_file(
                    a.get("path", ""), a.get("before", ""), a.get("after", "")
                )
            )
        else:
            results.append((t or "unknown", "SKIP: unknown action"))
    clear_plan()
    return results


def _write_file(path: str, content: str) -> Tuple[str, str]:
    if not is_safe_path(path):
        return (f"write_file:{path}", "DENY: unsafe path")
    p = Path(path).expanduser()
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    return (f"write_file:{p}", "OK")


def _append_file(path: str, content: str) -> Tuple[str, str]:
    if not is_safe_path(path):
        return (f"append_file:{path}", "DENY: unsafe path")
    p = Path(path).expanduser()
    p.parent.mkdir(parents=True, exist_ok=True)
    if p.exists():
        old = p.read_text(encoding="utf-8", errors="ignore")
    else:
        old = ""
    p.write_text(old + content, encoding="utf-8")
    return (f"append_file:{p}", "OK")


def _replace_in_file(path: str, before: str, after: str) -> Tuple[str, str]:
    if not is_safe_path(path):
        return (f"replace_in_file:{path}", "DENY: unsafe path")
    p = Path(path).expanduser()
    if not p.exists():
        return (f"replace_in_file:{p}", "ERR: not found")
    text = p.read_text(encoding="utf-8", errors="ignore")
    if before not in text:
        return (f"replace_in_file:{p}", "WARN: 'before' text not found")
    text = text.replace(before, after)
    p.write_text(text, encoding="utf-8")
    return (f"replace_in_file:{p}", "OK")
