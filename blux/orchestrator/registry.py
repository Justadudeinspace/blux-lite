from __future__ import annotations
import json, shutil
from pathlib import Path
from typing import Dict, Any, Optional, List
from blux.config import load_config

ROOT = Path(__file__).resolve().parent.parent.parent
CATALOG_DIR = ROOT / ".config" / "blux-lite-gold" / "catalogs"


def _which(cmd: str) -> bool:
    return shutil.which(cmd) is not None


def load_catalog(name: str) -> list[dict]:
    p = CATALOG_DIR / f"{name}.json"
    if not p.exists():
        return []
    return json.loads(p.read_text(encoding="utf-8"))


def engines_available() -> Dict[str, bool]:
    e = {eng["id"]: False for eng in load_catalog("engines")}
    e["ollama"] = _which("ollama") or e.get("ollama", False)
    e["vllm"] = _which("python") or e.get("vllm", False)
    e["tgi"] = _which("docker") or e.get("tgi", False)
    e["llama_cpp"] = _which("llama-cli") or _which("llama") or e.get("llama_cpp", False)
    return e


from blux.config import load_config


def pick_engine_for_model(
    model: Dict[str, Any], available: Dict[str, bool]
) -> Optional[str]:
    config = load_config()
    pref = config.get("engine_preference", ["ollama", "vllm", "tgi", "llama_cpp"])
    for p in pref:
        if p in model.get("serving_engines", []) and available.get(p):
            return p
    return None
