# -*- coding: utf-8 -*-
import os
from pathlib import Path
import click
from .settings import ROOT, SETTINGS
from .utils import which, run_cmd


def install_engines_interactive():
    if not which("git"):
        click.echo("git not found in PATH; please install git first.")
        return
    if not which("make"):
        click.echo("make not found in PATH; please install build tools first.")
        return
    click.echo("Engine setup — pick at least one to install\n")
    choices = [
        ("llama.cpp (GGUF runner)", "llama"),
        ("alpaca.cpp (future alpaca models)", "alpaca"),
        ("ollama (image puller/runner)", "ollama"),
        ("OpenAI compatible (requires OPENAI_API_KEY)", "openai"),
    ]
    for i, (label, _) in enumerate(choices, start=1):
        click.echo(f"[{i}] {label}")
    sel = click.prompt("\nEnter comma-separated choices", default="1")
    idx = {str(i): key for i, (_, key) in enumerate(choices, start=1)}
    picked = [idx.get(s.strip()) for s in sel.split(",") if s.strip() in idx]
    picked = [p for p in picked if p]
    if not picked:
        click.echo("No engines selected; nothing to do.")
        return

    if "llama" in picked:
        engines_dir = ROOT / "engines"
        engines_dir.mkdir(parents=True, exist_ok=True)
        repo = engines_dir / "llama.cpp"
        if not repo.exists():
            click.echo("\n[llama.cpp] Cloning...")
            code, out, err = run_cmd(
                [
                    "git",
                    "clone",
                    "https://github.com/ggerganov/llama.cpp.git",
                    str(repo),
                ],
                timeout=600,
            )
            if code != 0:
                click.echo(err or "Clone failed.")
        click.echo("[llama.cpp] Building...")
        code, out, err = run_cmd(
            ["make", "-C", str(repo), f"-j{os.cpu_count() or 2}"], timeout=1800
        )
        if code == 0:
            bin_candidate = repo / "llama-cli"
            if not bin_candidate.exists():
                bin_candidate = repo / "main"
            target = Path(str(SETTINGS["bin_dir"])) / "llama"  # type: ignore[arg-type]
            target.parent.mkdir(parents=True, exist_ok=True)
            try:
                if target.exists():
                    target.unlink()
                target.symlink_to(bin_candidate)
            except Exception:
                code_cp, _, err_cp = run_cmd(["cp", str(bin_candidate), str(target)])
                if code_cp != 0:
                    click.echo(f"Failed to install binary: {err_cp}")
            click.echo(f"[llama.cpp] Installed at {target}")
        else:
            click.echo("[llama.cpp] Build failed. See build logs above.")

    if "alpaca" in picked:
        engines_dir = ROOT / "engines"
        engines_dir.mkdir(parents=True, exist_ok=True)
        repo = engines_dir / "alpaca.cpp"
        if not repo.exists():
            click.echo("\n[alpaca.cpp] Cloning...")
            run_cmd(
                [
                    "git",
                    "clone",
                    "https://github.com/antimatter15/alpaca.cpp",
                    str(repo),
                ],
                timeout=600,
            )
        click.echo("[alpaca.cpp] Building...")
        code, out, err = run_cmd(
            ["make", "-C", str(repo), f"-j{os.cpu_count() or 2}"], timeout=1800
        )
        if code == 0:
            bin_candidate = repo / "alpaca"
            if not bin_candidate.exists():
                bin_candidate = repo / "main"
            target = Path(str(SETTINGS["bin_dir"])) / "alpaca"  # type: ignore[arg-type]
            target.parent.mkdir(parents=True, exist_ok=True)
            try:
                if target.exists():
                    target.unlink()
                target.symlink_to(bin_candidate)
            except Exception:
                code_cp, _, err_cp = run_cmd(["cp", str(bin_candidate), str(target)])
                if code_cp != 0:
                    click.echo(f"Failed to install binary: {err_cp}")
            click.echo(f"[alpaca.cpp] Installed at {target}")
        else:
            click.echo("[alpaca.cpp] Build failed (optional). See build logs above.")

    if "ollama" in picked:
        click.echo("\n[ollama] Installing or verifying...")
        if which("ollama"):
            click.echo("[ollama] Found in PATH.")
        else:
            click.echo("[ollama] Installing via official script…")
            code, out, err = run_cmd(
                ["sh", "-c", "curl -fsSL https://ollama.com/install.sh | sh"],
                timeout=1200,
            )
            if code == 0:
                click.echo(
                    "[ollama] Installer invoked. Re-run 'blux doctor' to verify."
                )
            else:
                click.echo(f"[ollama] Install script failed: {err or out}")

    if "openai" in picked:
        click.echo("\n[openai] Configure environment (REQUIRED to use):")
        click.echo("  export OPENAI_BASE_URL=https://api.openai.com")
        click.echo("  export OPENAI_API_KEY=sk-...")

    click.echo("\nDone. Try: blux doctor")
