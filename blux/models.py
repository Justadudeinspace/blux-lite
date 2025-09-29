import logging

logger = logging.getLogger("blux.models")
# -*- coding: utf-8 -*-
import os, time, json
from pathlib import Path
from typing import Optional, Tuple, Dict, List
import click
from .settings import SETTINGS
from .utils import run_cmd, log
from .router import detect_intent, sanitize_prompt
from .memory import save_memory
from .engines import (
    engines_installed,
    llama_bin,
    alpaca_bin,
    ollama_present,
    openai_enabled,
    run_llama_like,
    run_ollama,
    run_openai_compat,
    resolve_timeout_s,
)

# Catalog
MODEL_CATALOG: Dict[str, Dict[str, str]] = {
    # General
    "tinyllama": {
        "type": "gguf",
        "repo": "TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "phi2": {"type": "gguf", "repo": "TheBloke/phi-2-GGUF", "include": "*Q4_K_M*.gguf"},
    "mistral7b": {
        "type": "gguf",
        "repo": "TheBloke/Mistral-7B-Instruct-v0.2-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "llama3_8b": {
        "type": "gguf",
        "repo": "bartowski/Meta-Llama-3-8B-Instruct-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "qwen2_5_3b": {
        "type": "gguf",
        "repo": "Qwen/Qwen2.5-3B-Instruct-GGUF",
        "include": "*q4_k_m*.gguf",
    },
    "qwen2_5_7b": {
        "type": "gguf",
        "repo": "Qwen/Qwen2.5-7B-Instruct-GGUF",
        "include": "*q4_k_m*.gguf",
    },
    "llama2_7b": {
        "type": "gguf",
        "repo": "TheBloke/Llama-2-7B-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "gemma2_2b": {
        "type": "gguf",
        "repo": "bartowski/gemma-2-2b-it-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "hermes2_m7b": {
        "type": "gguf",
        "repo": "TheBloke/Nous-Hermes-2-Mistral-7B-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "openhermes_m7b": {
        "type": "gguf",
        "repo": "TheBloke/OpenHermes-2.5-Mistral-7B-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "dolphin_m7b": {
        "type": "gguf",
        "repo": "TheBloke/dolphin-2.6-mistral-7b-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "orca_mini_3b": {
        "type": "gguf",
        "repo": "TheBloke/orca_mini_3b-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    # Coding
    "codegemma_2b": {
        "type": "gguf",
        "repo": "bartowski/codegemma-2b-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "qwen2_5_coder_05b": {
        "type": "gguf",
        "repo": "Qwen/Qwen2.5-Coder-0.5B-Instruct-GGUF",
        "include": "*q8_0*.gguf",
    },
    "qwen2_5_coder_3b": {
        "type": "gguf",
        "repo": "Qwen/Qwen2.5-Coder-3B-GGUF",
        "include": "*q4_k_m*.gguf",
    },
    "starcoder2_3b": {
        "type": "gguf",
        "repo": "second-state/StarCoder2-3B-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "starcoder2_7b": {
        "type": "gguf",
        "repo": "mradermacher/starcoder2-7b-gguf",
        "include": "*Q4_K_M*.gguf",
    },
    "codellama_7b": {
        "type": "gguf",
        "repo": "TheBloke/CodeLlama-7B-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "wizardcoder_7b": {
        "type": "gguf",
        "repo": "TheBloke/WizardCoder-Python-7B-V1.0-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "wizardcoder_13b": {
        "type": "gguf",
        "repo": "TheBloke/WizardCoder-Python-13B-V1.0-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    "stablecode_3b": {
        "type": "gguf",
        "repo": "TheBloke/stablecode-3b-GGUF",
        "include": "*Q4_K_M*.gguf",
    },
    # Ollama convenience
    "mistral:latest": {"type": "ollama"},
}

LADDER_CODING = [
    "starcoder2_7b",
    "starcoder2_3b",
    "codellama_7b",
    "wizardcoder_13b",
    "wizardcoder_7b",
    "codegemma_2b",
    "qwen2_5_coder_3b",
    "qwen2_5_coder_05b",
]
LADDER_GENERAL = [
    "llama3_8b",
    "mistral7b",
    "qwen2_5_7b",
    "qwen2_5_3b",
    "gemma2_2b",
    "hermes2_m7b",
    "openhermes_m7b",
    "dolphin_m7b",
    "orca_mini_3b",
    "llama2_7b",
    "phi2",
    "tinyllama",
]


# HF downloader
def _ensure_hf_cli():
    from .utils import which

    for c in ("hf", "huggingface-cli"):
        if which(c):
            return c
    # Try installing hf tool (best-effort)
    from .utils import run_cmd

    run_cmd(
        [os.sys.executable, "-m", "pip", "install", "-U", "huggingface_hub[hf]"],
        timeout=180,
    )
    for c in ("hf", "huggingface-cli"):
        if which(c):
            return c
    return None


def hf_download(repo: str, include_glob: str, dest: Path) -> bool:
    dest.mkdir(parents=True, exist_ok=True)
    cli = _ensure_hf_cli()
    if not cli:
        click.echo("Hugging Face CLI not available.")
        logger.error("Hugging Face download failed.")
        return False
    if cli == "hf":
        code, _, _ = run_cmd(
            [
                "hf",
                "download",
                repo,
                "--include",
                include_glob,
                "--local-dir",
                str(dest),
            ],
            timeout=3600,
        )
    else:
        code, _, _ = run_cmd(
            [
                "huggingface-cli",
                "download",
                repo,
                include_glob,
                "--local-dir",
                str(dest),
            ],
            timeout=3600,
        )
    return code == 0


# Local/ollama scans (cached index)
CONF_DIR = Path(os.getenv("BLUX_CONF_DIR", Path.home() / ".config" / "blux-lite"))
MODEL_INDEX = CONF_DIR / "model_index.json"
MODEL_INDEX_TTL_S = 60


def _load_model_index():
    try:
        if MODEL_INDEX.exists():
            return json.loads(MODEL_INDEX.read_text(encoding="utf-8"))
    except Exception:
        pass
    return {"ts": 0, "items": []}


def _save_model_index(items):
    MODEL_INDEX.write_text(
        json.dumps({"ts": time.time(), "items": items}), encoding="utf-8"
    )


def scan_local_gguf(models_dir: str):
    now = time.time()
    idx = _load_model_index()
    if now - idx.get("ts", 0) < MODEL_INDEX_TTL_S:
        return idx.get("items", [])
    out = []
    p = Path(models_dir)
    if p.exists():
        for f in p.glob("**/*.gguf"):
            name = f.name.lower()
            tag = (
                "coding"
                if any(
                    h in name
                    for h in ["code", "coder", "starcoder", "codellama", "wizardcoder"]
                )
                else "general"
            )
            try:
                size_mb = f.stat().st_size / (1024 * 1024)
                age_days = max(0, (now - f.stat().st_mtime) / 86400.0)
            except Exception:
                size_mb, age_days = 0.0, 0.0
            out.append(
                {
                    "path": str(f),
                    "name": f.name,
                    "tag": tag,
                    "size_mb": round(size_mb, 1),
                    "age_days": round(age_days, 1),
                }
            )
    _save_model_index(out)
    return out


def refresh_model_index():
    if MODEL_INDEX.exists():
        try:
            MODEL_INDEX.unlink()
        except Exception:
            pass
    _ = scan_local_gguf(str(SETTINGS["models_dir"]))  # type: ignore[arg-type]


def scan_ollama_models() -> List[str]:
    from .utils import run_cmd

    if not ollama_present():
        return []
    code, out, _ = run_cmd(["ollama", "list"], timeout=20)
    if code != 0:
        return []
    names: List[str] = []
    for line in out.splitlines():
        parts = line.split()
        if parts:
            names.append(parts[0])
    return names


def choose_candidates(
    intent: str, local_gguf: List[Dict], ollama_models: List[str]
) -> List[Dict]:
    have = engines_installed()
    ladder = LADDER_CODING if intent == "coding" else LADDER_GENERAL
    cap = int(SETTINGS.get("candidate_limit", 4))
    chosen: List[Dict] = []

    def ggufs_for(idfrag: str):
        return [m for m in local_gguf if idfrag in m["name"].lower()]

    # Prefer local gguf with llama.cpp/alpaca.cpp
    if have["llama.cpp"] or have["alpaca.cpp"]:
        for idfrag in ladder:
            gg = ggufs_for(idfrag)
            gg.sort(
                key=lambda m: (0 if m["tag"] == intent else 1, m.get("age_days", 999))
            )
            if gg:
                engine = "llama.cpp" if have["llama.cpp"] else "alpaca.cpp"
                chosen.append(
                    {
                        "engine": engine,
                        "id": idfrag,
                        "target": gg[0]["path"],
                        "tag": gg[0]["tag"],
                    }
                )
            if len(chosen) >= cap:
                break

    # Add Ollama if present
    if have["ollama"]:
        lower_already = {c["id"] for c in chosen}
        for idfrag in ladder:
            if len(chosen) >= cap:
                break
            if idfrag in lower_already:
                continue
            for om in ollama_models:
                normalized = (
                    om.replace(":", "").replace("-", "").replace("_", "").lower()
                )
                if idfrag.replace("_", "") in normalized:
                    chosen.append(
                        {"engine": "ollama", "id": idfrag, "target": om, "tag": intent}
                    )
                    break

    # Fallback OpenAI (only if configured)
    if not chosen and have["openai"]:
        chosen.append({"engine": "openai", "id": "openai_compat", "target": SETTINGS["openai_model"], "tag": intent})  # type: ignore[index]

    # If still nothing but alpaca exists and there is any gguf, pick one
    if not chosen and have["alpaca.cpp"] and local_gguf:
        local_gguf.sort(key=lambda m: m.get("age_days", 999))
        chosen.append(
            {
                "engine": "alpaca.cpp",
                "id": "gguf_auto",
                "target": local_gguf[0]["path"],
                "tag": intent,
            }
        )

    # dedupe
    seen = set()
    ded = []
    for c in chosen:
        k = (c["engine"], c["target"])
        if k in seen:
            continue
        seen.add(k)
        ded.append(c)
    return ded[:cap]


# Model inference (no --engine needed)
def infer_engine_and_prepare(model_spec: str):
    have = engines_installed()
    ms = model_spec.strip()

    # Explicit prefixes
    if ms.startswith("openai:"):
        return ("openai" if have["openai"] else None), ms.split(":", 1)[1]
    if ms.startswith("ollama:"):
        image = ms.split(":", 1)[1]
        if have["ollama"]:
            run_cmd(["ollama", "pull", image], timeout=3600)
        return ("ollama" if have["ollama"] else None), image

    # Looks like an Ollama image (contains ':', no path)
    if ":" in ms and "/" not in ms and not ms.endswith(".gguf"):
        if have["ollama"]:
            run_cmd(["ollama", "pull", ms], timeout=3600)
        return ("ollama" if have["ollama"] else None), ms

    # Local GGUF
    p = Path(ms).expanduser()
    if p.suffix.lower() == ".gguf":
        engine = (
            "llama.cpp"
            if have["llama.cpp"]
            else ("alpaca.cpp" if have["alpaca.cpp"] else None)
        )
        return engine, str(p) if p.exists() else None

    # Catalog ID (gguf)
    meta = MODEL_CATALOG.get(ms)
    if meta and meta.get("type") == "gguf":
        if not (have["llama.cpp"] or have["alpaca.cpp"]):
            return None, None
        dest = Path(str(SETTINGS["models_dir"]))  # type: ignore[arg-type]
        repo, inc = meta["repo"], meta["include"]
        found = list(dest.glob(inc))
        if not found:
            ok = hf_download(repo, inc, dest)
            if ok:
                refresh_model_index()
                found = list(dest.glob(inc))
        if found:
            found.sort(key=lambda f: -f.stat().st_mtime)
            engine = "llama.cpp" if have["llama.cpp"] else "alpaca.cpp"
            return engine, str(found[0])
        else:
            return None, None

    # Catalog ID of ollama
    if meta and meta.get("type") == "ollama":
        if have["ollama"]:
            run_cmd(["ollama", "pull", ms], timeout=3600)
        return ("ollama" if have["ollama"] else None), ms

    # OpenAI last
    return (("openai" if have["openai"] else None), ms)


# Fanout & merge
def fanout_hivemind(
    prompt: str, intent: str, max_workers: int, timeout_override: Optional[int]
):
    from concurrent.futures import ThreadPoolExecutor, as_completed

    local = scan_local_gguf(str(SETTINGS["models_dir"]))  # type: ignore[arg-type]
    ollama_list = scan_ollama_models()
    cands = choose_candidates(intent, local, ollama_list)
    if not cands:
        return []
    from .engines import (
        run_openai_compat,
        run_ollama,
        run_llama_like,
        resolve_timeout_s,
        llama_bin,
        alpaca_bin,
    )

    results = []

    def run_cand(c):
        eng = c["engine"]
        label = ""
        if eng == "llama.cpp":
            b = llama_bin()
            label = f"llama.cpp:{Path(c['target']).name}"
            t = resolve_timeout_s(timeout_override, "llama_timeout_s")
            out = run_llama_like(b, c["target"], prompt, t) if b else None
        elif eng == "alpaca.cpp":
            b = alpaca_bin()
            label = f"alpaca.cpp:{Path(c['target']).name}"
            t = resolve_timeout_s(timeout_override, "alpaca_timeout_s")
            out = run_llama_like(b, c["target"], prompt, t) if b else None
        elif eng == "ollama":
            label = f"ollama:{c['target']}"
            t = resolve_timeout_s(timeout_override, "ollama_timeout_s")
            out = run_ollama(c["target"], prompt, t)
        elif eng == "openai":
            label = f"openai:{c.get('target')}"
            t = resolve_timeout_s(timeout_override, "openai_timeout_s")
            out = run_openai_compat(prompt, c.get("target"), t)
        else:
            out = None
        return (label, out)

    with ThreadPoolExecutor(max_workers=max_workers or 1) as ex:
        futs = [ex.submit(run_cand, c) for c in cands]
        for f in as_completed(futs):
            label, out = f.result()
            if out and out.strip():
                t = out.strip()
                if (
                    len(t) > len(prompt)
                    and prompt.lower() in t.lower()[: len(prompt) + 16]
                ):
                    t = t[len(prompt) :].lstrip("\n:> ")
                results.append((label, t))
    return results


def _dedupe_similar(texts: List[tuple]):
    kept = []

    def toks(s: str):
        import re

        return set(re.findall(r"\w+", s.lower()))

    for name, t in texts:
        tk = toks(t)
        is_dup = False
        for _, kept_t in kept:
            kk = toks(kept_t)
            inter = len(tk & kk)
            union = len(tk | kk) or 1
            if inter / union >= 0.9:
                is_dup = True
                break
        if not is_dup:
            kept.append((name, t))
    return kept


def merge_answers(results: List[tuple]) -> str:
    if not results:
        return "No engine produced an answer."
    ranked = sorted(results, key=lambda nt: (-len(nt[1]), nt[0]))
    ranked = _dedupe_similar(ranked)
    primary_name, primary_txt = ranked[0]
    others = ranked[1:]
    blocks = [primary_txt]
    for name, txt in others:
        blocks.append(f"\n---\n[{name}] says:\n{txt}")
    return "\n".join(blocks)


def ensure_any_engine_or_exit():
    ei = engines_installed()
    if not any(ei.values()):
        click.echo("No engines installed. Run: blux installer engines")
        raise SystemExit(2)


def auto_or_forced_run(
    intent: str,
    model: str,
    project: Optional[str],
    no_memory: bool,
    mem_policy: Optional[str],
    top_n: Optional[int],
    timeout: Optional[int],
    prompt_words: tuple,
):
    ensure_any_engine_or_exit()
    text = " ".join(prompt_words).strip()
    if not text:
        click.echo("Provide a prompt.")
        return
    try:
        text = sanitize_prompt(text)
    except ValueError as ve:
        click.echo(f"Input rejected: {ve}")
        return

    project_name = project or str(SETTINGS.get("project", "default"))
    mem_policy_effective = mem_policy or str(SETTINGS.get("memory_policy", "prompt"))
    if top_n is not None:
        SETTINGS["candidate_limit"] = int(top_n)

    # Forced model path
    if model:
        eng, tgt = infer_engine_and_prepare(model)
        if not eng or not tgt:
            click.echo(
                "Could not infer engine or prepare model. Check installer engines and model id/path."
            )
            return
        if eng == "llama.cpp":
            merged = (
                run_llama_like(
                    llama_bin(),
                    tgt,
                    text,
                    resolve_timeout_s(timeout, "llama_timeout_s"),
                )
                or "No output."
            )
        elif eng == "alpaca.cpp":
            merged = (
                run_llama_like(
                    alpaca_bin(),
                    tgt,
                    text,
                    resolve_timeout_s(timeout, "alpaca_timeout_s"),
                )
                or "No output."
            )
        elif eng == "ollama":
            merged = (
                run_ollama(tgt, text, resolve_timeout_s(timeout, "ollama_timeout_s"))
                or "No output."
            )
        elif eng == "openai":
            if not openai_enabled():
                click.echo("OpenAI engine requires OPENAI_BASE_URL and OPENAI_API_KEY.")
                return
            merged = (
                run_openai_compat(
                    text, tgt, resolve_timeout_s(timeout, "openai_timeout_s")
                )
                or "No output."
            )
        else:
            click.echo("Unsupported engine.")
            return
        click.echo(merged)
        if not no_memory and mem_policy_effective != "never":
            save_memory(project_name, text, merged)
        return

    # Auto
    if intent == "auto":
        intent = detect_intent(text)
    click.echo(f"[intent={intent}]")
    results = fanout_hivemind(text, intent, int(SETTINGS.get("max_workers", 2)), timeout)  # type: ignore[arg-type]
    if not results:
        if not any(engines_installed().values()):
            click.echo("No engines installed. Run: blux installer engines")
        else:
            click.echo("No available engines or all calls failed.")
        return
    merged = merge_answers(results)
    if SETTINGS.get("json_output", False):  # type: ignore[arg-type]
        click.echo(
            json.dumps(
                {
                    "intent": intent,
                    "candidates": [{"name": n, "chars": len(t)} for n, t in results],
                    "answer": merged,
                },
                ensure_ascii=False,
            )
        )
    else:
        click.echo(merged)
    if not no_memory and mem_policy_effective != "never":
        save_memory(project_name, text, merged)
