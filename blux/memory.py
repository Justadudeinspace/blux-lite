# -*- coding: utf-8 -*-
from pathlib import Path
from datetime import datetime
import json, logging
from typing import Optional, List, Dict
from .settings import SETTINGS

logger = logging.getLogger("blux.memory")


def libf_path(project: str) -> Path:
    base = Path(str(SETTINGS["libf_projects_dir"]))  # repo-local
    p = base / project / "history"
    p.mkdir(parents=True, exist_ok=True)
    return p / "history.jsonl"


def _rotate_if_needed(path: Path, max_lines: int = 5000):
    try:
        if not path.exists():
            return
        with path.open("r", encoding="utf-8") as f:
            for i, _ in enumerate(f, 1):
                if i > max_lines:
                    ts = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
                    backup = path.with_name(f"{path.stem}.{ts}.jsonl")
                    path.replace(backup)
                    logger.info("Rotated memory file to %s", backup.name)
                    return
    except Exception:
        pass


def save_memory(project: str, prompt: str, answer: str):
    pol = str(SETTINGS.get("memory_policy", "prompt"))
    if pol == "never":
        return
    if pol == "prompt" and len(prompt) < 8:
        return
    entry = {
        "ts": datetime.utcnow().isoformat() + "Z",
        "project": project,
        "prompt": prompt,
        "answer": answer,
    }
    path = libf_path(project)
    _rotate_if_needed(path, int(SETTINGS.get("memory_max_lines", 5000)))
    try:
        with open(path, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception as e:
        logger.error("Failed to write memory: %s", e)


def list_sessions(project: Optional[str] = None) -> List[Dict]:
    project = project or str(SETTINGS.get("project", "default"))
    path = libf_path(project)
    out: List[Dict] = []
    if path.exists():
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                try:
                    out.append(json.loads(line))
                except Exception:
                    pass
    return out
