# -*- coding: utf-8 -*-
import os, sys, re, json, time, subprocess, logging, random
from pathlib import Path
from typing import Optional, List, Tuple
import click

LOG_PATH = Path.home() / ".config" / "blux-lite" / "blux_lite.log"
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_PATH, encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("blux-lite")


def which(cmd: str) -> Optional[str]:
    from shutil import which as _which

    return _which(cmd)


def run_cmd(
    cmd: List[str], input_text: Optional[str] = None, timeout: int = 120
) -> Tuple[int, str, str]:
    try:
        proc = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE if input_text is not None else None,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        out, err = proc.communicate(input=input_text, timeout=timeout)
        return proc.returncode, out or "", err or ""
    except subprocess.TimeoutExpired:
        return 124, "", "Timeout"
    except Exception as e:
        return 1, "", f"{type(e).__name__}: {e}"


def with_retries(fn, attempts=2, base_delay=0.4, jitter=0.25):
    for i in range(attempts):
        try:
            val = fn()
            if val:
                return val
        except Exception:
            pass
        if i < attempts - 1:
            time.sleep(base_delay * (1.7**i) + random.random() * jitter)
    return None


# Security / input sanitation
INJECTION_PATTERNS = [r"[;&`]", r"\|\|", r"\&\&", r"\$\(", r"\<\s*", r"\>\s*"]
_INJ = [re.compile(p) for p in INJECTION_PATTERNS]


def sanitize_prompt(prompt: str) -> str:
    p = prompt.strip()
    for rx in _INJ:
        if rx.search(p):
            raise ValueError(
                "Input contains disallowed shell-like characters or patterns."
            )
    return p


# Click helper: print command tree in --help
class TreeGroup(click.Group):
    def format_help(self, ctx, formatter):
        super().format_help(ctx, formatter)

        def walk(cmd: click.MultiCommand, prefix=""):
            lines = []
            for name in sorted(cmd.list_commands(ctx)):
                sub = cmd.get_command(ctx, name)
                if isinstance(sub, click.MultiCommand):
                    lines.append(f"{prefix}{name}/")
                    lines += walk(sub, prefix + "  ")
                else:
                    lines.append(f"{prefix}{name}")
            return lines

        formatter.write("\nCommand tree:\n")
        for line in walk(self):
            formatter.write(f"  {line}\n")
