from __future__ import annotations
import json, shutil, subprocess, os, re
from pathlib import Path
from typing import Optional, Dict, Any
from .router import route

ROOT = Path(__file__).resolve().parent.parent.parent
CATALOG_DIR = ROOT / ".config" / "blux-lite-gold" / "catalogs"
MODELS = (
    json.loads((CATALOG_DIR / "models.json").read_text(encoding="utf-8"))
    if (CATALOG_DIR / "models.json").exists()
    else []
)


def _which(cmd: str) -> bool:
    return shutil.which(cmd) is not None


def _lookup_model(mid: str | None) -> Optional[Dict[str, Any]]:
    if not mid:
        return None
    for m in MODELS:
        if m.get("id") == mid:
            return m
    return None


def _detect_language(text: str) -> str:
    if re.search(r"```(python|py)", text, re.I):
        return "python"
    if re.search(r"```(bash|sh)", text, re.I):
        return "bash"
    if re.search(r"\\bdef\\s+\\w+\\(", text):
        return "python"
    if re.search(r"\\bfor\\s+\\w+\\s+in\\s+\\$\\(", text):
        return "bash"
    return "text"


def _eval_if_code(text: str) -> Optional[str]:
    lang = _detect_language(text)
    if lang == "python":
        from .evaluator.python import syntax_ok

        code = re.sub(r"^```python\\n|```$", "", text, flags=re.I | re.M).strip()
        return "python:syntax=ok" if syntax_ok(code) else "python:syntax=error"
    if lang == "bash":
        from .evaluator.bash import syntax_ok

        code = re.sub(r"^```(bash|sh)\\n|```$", "", text, flags=re.I | re.M).strip()
        return "bash:syntax=ok" if syntax_ok(code) else "bash:syntax=error"
    return None


def ai_respond(prompt: str, model_id: Optional[str] = None) -> str:
    m = _lookup_model(model_id) if model_id else None
    if not m:
        echo = _eval_if_code(prompt) or "text"
        return f"[stub({echo})] {prompt}"
    engine = route(m)
    if engine == "ollama" and m.get("weights", {}).get("ollama") and _which("ollama"):
        tag = m["weights"]["ollama"]
        try:
            out = subprocess.run(
                ["ollama", "run", tag],
                input=prompt,
                text=True,
                check=True,
                capture_output=True,
            ).stdout
            return out
        except subprocess.CalledProcessError as e:
            return f"[runner error] {e}"
    if m.get("api"):
        return f"[AI via API not executed here] Use provider API at {m['api']}"
    echo = _eval_if_code(prompt) or "text"
    return f"[stub({echo})] {prompt}"
