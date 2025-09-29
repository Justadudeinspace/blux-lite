# -*- coding: utf-8 -*-
import os, sys, json, subprocess, time, logging, logging.config

LOGCFG = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    ".config",
    "blux-lite-gold",
    "logging.json",
)


def tail_log(path: str, n: int = 50) -> None:
    try:
        import subprocess

        subprocess.run(["tail", "-n", str(n), path], check=False)
    except Exception:
        pass


def doctor() -> int:
    # minimal placeholder; expand with real checks if you have them elsewhere
    print("Legacy doctor: OK")
    return 0


def main() -> int:
    # your existing legacy menu logic here...
    print("Legacy menu ready")
    return 0


def setup_logging():
    try:
        with open(LOGCFG, "r") as f:
            cfg = json.load(f)
        logging.config.dictConfig(cfg)
    except Exception as e:
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
        )
    return logging.getLogger("blux.legacy")


from .legacy_menu import tail_log, doctor  # re-import helpers if needed


def menu():
    log = setup_logging()
    while True:
        print("\n=== BLUX Legacy Menu ===")
        print("1) Run Doctor (checks & env)")
        print("2) Launch TUI")
        print("3) View Logs (tail)")
        print("4) Run Quick Orchestrator Demo")
        print("5) Exit")
        print("6) Setup/Wizard (choose model & keys)")
        print("7) Auto Orchestrate (skill/dataset aware)")
        choice = input("> ").strip()
        if choice == "1":
            doctor()
        elif choice == "2":
            try:
                code = subprocess.call([sys.executable, "-m", "blux.cli", "tui"])
                print(f"[TUI exited] code={code}")
            except KeyboardInterrupt:
                pass
        elif choice == "3":
            tail_log(200)
        elif choice == "4":
            log.info("Orchestrator demo: (placeholder)")
            print("Pretend demo run.")
        elif choice == "6":
            subprocess.call([sys.executable, "-m", "blux.cli", "setup"])
        elif choice == "7":
            task = input("Task: ").strip() or "print hello"
            subprocess.call([sys.executable, "-m", "blux.cli", "auto", task])
        elif choice == "5":
            print("Goodbye.")
            return 0
        else:
            print("Invalid choice.")
