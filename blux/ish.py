from __future__ import annotations
import os, sys, json
from urllib.parse import urlparse, parse_qs
from http.server import BaseHTTPRequestHandler, HTTPServer
import socketserver

try:
    import readline  # noqa: F401
except Exception:
    readline = None

ROOT = Path(__file__).resolve().parent.parent
CONFIG_DIR = ROOT / ".config" / "blux-lite-gold"
HIST_DIR = CONFIG_DIR / "shell"
HIST_DIR.mkdir(parents=True, exist_ok=True)
HIST_FILE = HIST_DIR / "history.txt"

BANNER = "BLUX Lite GOLD — Integrated Shell (type :help)"
PROMPT = "[BLG] {cwd}$ "

BLG_COMMANDS = {
    ":help": "Show help for BLUX shell commands",
    ":exit": "Exit the shell",
    ":quit": "Exit the shell",
    ":ai": "Send a prompt to the AI interface (stub; routes to future orchestrator)",
    ":py": "Enter a Python REPL (Ctrl-D to return)",
    ":catalog": "List models from the catalog (python -m blux.catalog_install models)",
    ":plan": "Print install plan for a model (usage: :plan <model_id>)",
    ":apply": "Apply install plan for a model (usage: :apply <model_id>)",
    ":doctor": "Run system doctor",
    ":logs": "Show latest logs",
    ":cd": "Change directory (usage: :cd <path>)",
}


def save_history(line: str) -> None:
    try:
        with HIST_FILE.open("a", encoding="utf-8") as f:
            f.write(line.rstrip() + "\n")
    except Exception:
        pass


def print_help() -> None:
    width = max(len(k) for k in BLG_COMMANDS)
    print("BLUX Commands:")
    for k, v in sorted(BLG_COMMANDS.items()):
        print(f"  {k.ljust(width)}  {v}")
    print(
        "\nAll other input is executed in your system shell. Use Ctrl-C to cancel a running command."
    )


def run(cmd: list[str]) -> int:
    try:
        return subprocess.call(cmd)
    except KeyboardInterrupt:
        return 130


def run_shell(line: str) -> int:
    try:
        # Let the user's shell handle it
        return subprocess.call(line, shell=True)
    except KeyboardInterrupt:
        return 130


def python_repl() -> int:
    import code

    banner = "BLUX Python REPL — exit with Ctrl-D"
    code.interact(banner=banner, local={})
    return 0


def main(argv=None) -> int:
    argv = argv or sys.argv[1:]
    # Non-interactive passthrough
    if argv:
        return run_shell(" ".join(shlex.quote(a) for a in argv))
    print(BANNER)
    while True:
        try:
            cwd = os.getcwd()
            line = input(PROMPT.format(cwd=cwd))
        except EOFError:
            print()
            return 0
        except KeyboardInterrupt:
            print()
            continue
        line = line.strip()
        if not line:
            continue
        save_history(line)
        # BLG commands
        if line in (":exit", ":quit"):
            return 0
        if line == ":help":
            print_help()
            continue
        if line.startswith(":cd"):
            parts = shlex.split(line)
            if len(parts) < 2:
                print("usage: :cd <path>")
                continue
            try:
                os.chdir(os.path.expanduser(parts[1]))
            except Exception as e:
                print(f"[ERR] cd: {e}")
            continue
        if line.startswith(":py"):
            python_repl()
            continue
        if line.startswith(":ai"):
            prompt = line[len(":ai") :].strip()
            if not prompt:
                print("usage: :ai <prompt>")
            else:
                # Stub for future orchestrator
                print(f"[AI] (stub) -> {prompt}")
            continue
        if line == ":catalog":
            rc = run([sys.executable, "-m", "blux.catalog_install", "models"])
            if rc != 0:
                print("[ERR] catalog list failed")
            continue
        if line.startswith(":plan"):
            parts = shlex.split(line)
            if len(parts) != 2:
                print("usage: :plan <model_id>")
                continue
            rc = run([sys.executable, "-m", "blux.catalog_install", "plan", parts[1]])
            continue
        if line.startswith(":apply"):
            parts = shlex.split(line)
            if len(parts) != 2:
                print("usage: :apply <model_id>")
                continue
            rc = run([sys.executable, "-m", "blux.catalog_install", "apply", parts[1]])
            continue
        if line.startswith(":ls"):
            parts = shlex.split(line)
            from .tools.fs import ls as _ls

            print(_ls(parts[1] if len(parts) > 1 else "."))
            continue
        if line.startswith(":open"):
            parts = shlex.split(line)
            if len(parts) != 2:
                print("usage: :open <path>")
                continue
            from .tools.fs import read as _read

            print(_read(parts[1]))
            continue
        if line.startswith(":new"):
            parts = shlex.split(line, posix=True)
            if len(parts) < 2:
                print("usage: :new <path>")
                continue
            path = parts[1]
            print("Enter content, end with a single line containing only 'EOF'")
            buf = []
            while True:
                try:
                    s = input()
                except EOFError:
                    break
                if s.strip() == "EOF":
                    break
                buf.append(s)
            from .tools.fs import write as _write

            print(_write(path, "\n".join(buf)))
            continue
        if line.startswith(":git"):
            parts = shlex.split(line)
            sub = parts[1] if len(parts) > 1 else "status"
            if sub == "status":
                from .tools.git import status as _status

                print(_status())
                continue
            if sub == "diff":
                from .tools.git import diff as _diff

                arg = parts[2] if len(parts) > 2 else ""
                print(_diff(arg))
                continue
            print("usage: :git status | :git diff [path]")
            continue

        # Otherwise, system shell
        rc = run_shell(line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
