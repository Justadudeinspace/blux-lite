# -*- coding: utf-8 -*-
from typing import Dict, Any, Optional

import httpx
from .utils import log


def llama_bin() -> Optional[str]:
    candidate = Path(str(SETTINGS["bin_dir"])) / "llama"  # type: ignore[arg-type]
    if candidate.exists():
        return str(candidate)
    return which("llama") or which("llama-cli") or which("main")


def alpaca_bin() -> Optional[str]:
    candidate = Path(str(SETTINGS["bin_dir"])) / "alpaca"  # type: ignore[arg-type]
    if candidate.exists():
        return str(candidate)
    return which("alpaca") or which("alpaca-cli")


def ollama_present() -> bool:
    return which("ollama") is not None


def openai_enabled() -> bool:
    return bool(
        str(SETTINGS.get("openai_base_url", "")).strip()
        and str(SETTINGS.get("openai_api_key", "")).strip()
    )


def engines_installed() -> Dict[str, bool]:
    return {
        "llama.cpp": bool(llama_bin()),
        "alpaca.cpp": bool(alpaca_bin()),
        "ollama": bool(ollama_present()),
        "openai": bool(openai_enabled()),
    }


def resolve_timeout_s(override: Optional[int], key: str) -> int:
    if override is not None and override > 0:
        return int(override)
    return int(SETTINGS.get(key, 180))


def run_llama_like(
    binpath: str, model_path: str, prompt: str, timeout_s: int
) -> Optional[str]:
    if not binpath or not Path(model_path).exists():
        return None
    mt = int(SETTINGS["max_tokens"])
    tp = float(SETTINGS["temperature"])
    cmd = [binpath, "-m", model_path, "-p", prompt, "-n", str(mt), "-temp", str(tp)]
    code, out, err = run_cmd(cmd, timeout=timeout_s)
    if code == 0 and out.strip():
        return out.strip()
    log.debug(f"{Path(binpath).name} error: {err}")
    return None


def run_llama_stream(
    binpath: str, model_path: str, prompt: str, timeout_s: int
) -> Optional[str]:
    # streaming variant for local llama/alpaca — implemented inline in models for simplicity
    return run_llama_like(binpath, model_path, prompt, timeout_s)


def run_ollama(model_name: str, prompt: str, timeout_s: int) -> Optional[str]:
    if not ollama_present():
        return None
    code, out, err = run_cmd(["ollama", "list"], timeout=20)
    known = set()
    if code == 0:
        for line in out.splitlines():
            if line.strip():
                known.add(line.split()[0])
    if model_name not in known:
        run_cmd(["ollama", "pull", model_name], timeout=3600)
    code, out, err = run_cmd(
        ["ollama", "run", model_name], input_text=prompt, timeout=timeout_s
    )
    if code == 0 and out.strip():
        return out.strip()
    log.debug(f"Ollama error: {err}")
    return None


def run_openai_compat(
    prompt: str, model: Optional[str], timeout_s: int
) -> Optional[str]:
    if not openai_enabled():
        return None
    try:
        import requests
    except Exception:
        log.debug("requests not installed for OpenAI-compatible calls.")
        return None
    base = str(SETTINGS["openai_base_url"]).rstrip("/")
    api_key = str(SETTINGS["openai_api_key"])
    mdl = model or str(SETTINGS.get("openai_model", "gpt-3.5-turbo"))
    url = f"{base}/v1/chat/completions"
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    data = {
        "model": mdl,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": float(SETTINGS.get("temperature", 0.2)),
        "max_tokens": int(SETTINGS.get("max_tokens", 256)),
    }
    try:
        r = requests.post(url, headers=headers, json=data, timeout=timeout_s)
        if r.status_code == 200:
            js = r.json()
            txt = (js.get("choices", [{}])[0].get("message", {}) or {}).get(
                "content", ""
            )
            return (txt or "").strip() or None
        else:
            log.debug(f"OpenAI-compatible HTTP {r.status_code}: {r.text[:200]}")
    except Exception as e:
        log.debug(f"OpenAI-compatible error: {e}")
    return None
