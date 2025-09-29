from __future__ import annotations
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG_DIR = ROOT / ".config" / "blux-lite-gold" / "catalogs"


def load_json(name: str):
    p = CATALOG_DIR / name
    return json.loads(p.read_text(encoding="utf-8"))


def which(cmd: str) -> bool:
    return shutil.which(cmd) is not None


PREFERRED_ENGINES = ["ollama", "vllm", "tgi", "llama_cpp"]


def pick_engine(model: dict) -> str | None:
    available = set(PREFERRED_ENGINES) & set(model.get("serving_engines", []))
    for e in PREFERRED_ENGINES:
        if e in available:
            return e
    return None


def print_hw(m: dict):
    hw = m.get("hardware", {})
    if not hw:
        return
    print("Hardware:")
    print(f"  OS: {', '.join(hw.get('os_support', [])) or 'n/a'}")
    print(f"  RAM(min): {hw.get('min_ram_gb','?')} GB")
    print(
        f"  VRAM(min/reco): {hw.get('min_vram_gb','?')}/{hw.get('recommended_vram_gb','?')} GB"
    )
    print(f"  Disk(~): {hw.get('disk_gb','?')} GB")
    cpu = hw.get("cpu", {})
    print(
        f"  CPU: arch={', '.join(cpu.get('arch', [])) or 'n/a'}, cores_min={cpu.get('cores_min', '?')}"
    )
    gpu = hw.get("gpu", {})
    print(f"  GPU: arch={', '.join(gpu.get('arch', [])) or 'n/a'}; {gpu.get('notes', '')}")
    if "quantization" in hw:
        print(f"  Quantization: {', '.join(hw['quantization'])}")
    if hw.get("notes"):
        print(f"  Notes: {hw['notes']}")


def plan_install(model_id: str) -> list[str]:
    models = {m["id"]: m for m in load_json("models.json")}
    m = models.get(model_id)
    if not m:
        print(f"Model '{model_id}' not found.")
        return []
    cmds: list[str] = []
    print_hw(m)
    engine = pick_engine(m)
    weights = m.get("weights", {})
    vram = m.get("min_vram_gb")

    if vram:
        cmds.append(f"echo 'Hint: ~{vram} GB VRAM recommended for {model_id}'")

    if engine == "ollama" and "ollama" in weights:
        tag = weights["ollama"]
        if which("ollama"):
            cmds.append(f"ollama pull {tag}")
        else:
            cmds.append(
                "echo 'Install Ollama first: https://ollama.com' && echo 'Then: ollama pull {tag}'"
            )
    elif engine in ("vllm", "tgi"):
        if "hf" in weights:
            cmds.append(f"echo 'Use {engine} to serve HF model: {weights['hf']}'")
            if engine == "vllm":
                cmds.append(
                    f"echo 'Example: python -m vllm.entrypoints.openai.api_server --model <hf_model>'"
                )
            else:
                cmds.append(
                    f"echo 'Example: docker run -p 8080:80 ghcr.io/huggingface/text-generation-inference:latest --model-id <hf_model>'"
                )
        elif m.get("api"):
            cmds.append(f"echo 'Hosted API only: {m['api']}'")
    elif engine == "llama_cpp":
        if "hf" in weights:
            cmds.append(
                f"echo 'Convert/download GGUF and run with llama.cpp. Model: {weights['hf']}'"
            )
        else:
            cmds.append(
                "echo 'llama.cpp flow: convert to GGUF or use community GGUF builds'"
            )
    else:
        if "ollama" in weights:
            cmds.append(
                f"echo 'Suggested engine: Ollama → ollama pull {weights['ollama']}'"
            )
        elif "hf" in weights:
            cmds.append(f"echo 'Download from HF: {weights['hf']}'")
        elif m.get("api"):
            cmds.append(f"echo 'Use provider API: {m['api']}'")
    return cmds


def list_items(kind: str, filter_text: str | None):
    items = load_json(f"{kind}.json")
    for it in items:
        tid = it.get("id", "")
        prov = it.get("provider", "")
        name = it.get("name", "")
        task = ",".join(it.get("task", [])) if kind == "models" else it.get("type", "")
        line = f"{tid:26} {prov:12} {name:36} {task}"
        if not filter_text or filter_text.lower() in line.lower():
            print(line)


def apply(commands: list[str]) -> int:
    rc = 0
    for c in commands:
        print(f"$ {c}")
        try:
            rc = subprocess.call(c, shell=True)
            if rc != 0:
                print(f"[WARN] Command failed with code {rc}")
        except Exception as e:
            print(f"[ERROR] {e}")
            rc = 1
    return rc


def main(argv=None):
    ap = argparse.ArgumentParser(
        prog="blux-catalog", description="BLUX Lite GOLD catalogs"
    )
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_eng = sub.add_parser("engines", help="list engines")
    p_eng.add_argument("--filter", help="substring filter")

    p_mod = sub.add_parser("models", help="list models")
    p_mod.add_argument("--filter", help="substring filter")

    p_plan = sub.add_parser("plan", help="print install plan")
    p_plan.add_argument("model_id")

    p_apply = sub.add_parser("apply", help="execute install plan")
    p_apply.add_argument("model_id")

    args = ap.parse_args(argv)

    if args.cmd == "engines":
        list_items("engines", args.filter)
        return 0
    if args.cmd == "models":
        list_items("models", args.filter)
        return 0
    if args.cmd == "plan":
        cmds = plan_install(args.model_id)
        if cmds:
            print("\n".join(cmds))
        return 0 if cmds else 1
    if args.cmd == "apply":
        cmds = plan_install(args.model_id)
        return apply(cmds)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
__":
    raise SystemExit(main())
   raise SystemExit(main())
in())
   raise SystemExit(main())
