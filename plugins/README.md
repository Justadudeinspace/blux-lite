### Quickstart

### Quickstart

**First run (initial setup):**
```bash
cd blux-lite
chmod +x first_start.sh
./first_start.sh
```
This script will:
- set permissions
- install/verify dependencies
- prepare config folders
- **generate `auto-start.sh`**

**After first run (normal use):**
```bash
./auto-start.sh
```
This launches `blux-lite.sh` (Legacy/TUI menu).

# BLUX Lite — Plugin System

BLUX Lite supports a modular plugin system to extend the `blux` CLI.  
Any `*.py` file placed inside the `plugins/` directory is auto-loaded at startup and should define a single entrypoint:

```python
def register(cli: click.Group) -> None:
    # attach commands/groups to the main CLI
```

---

# Included Plugins

> sys — Environment info, engine availability, and model storage stats.

> catalog — List, search, and download models from the built-in catalog.

> project — Show/set the current project; list recent .libf memory sessions.

> libf-note — Append a note into the project’s .libf history.

> libf-save — Save a complete context/session into a .libf project history.

> libf-export — Export .libf history to Markdown or JSON, with date/tag filters.

> router — Inspect which intent the router would pick for a given prompt.

> bench — Quick latency benchmarks for local or OpenAI-compatible engines.

> savscrip — Save generated code/output into timestamped Markdown files, with language auto-tagging, tags, and optional --open.

> plug — Browse, inspect, and open installed plugins interactively or via list/info commands.



---

# Usage Examples

## System info
```python
blux sys info
blux sys engines
blux sys storage
```

## Catalog
```python
blux catalog list
blux catalog search qwen
blux catalog download tinyllama qwen2_5_3b
```

## Project & memory
```python
blux project show
blux project set myapp
blux project sessions --last 5
blux libf-note "Refactor plan" --text "Switch to qwen2.5-3b, temp=0.3"
blux libf-save MyProject --title "Sprint notes" --file ./session.txt --tag planning
blux libf-export MyProject --format md --since 2025-08-01 --tag coding
```

## Router introspection
```python
blux router test "Write a Python function to sum a list"
```

## Quick benchmarks
```python
blux bench local --n 32
blux bench api --model openai:gpt-4o-mini
```

## Save scripts
```python
blux coding "write a python CLI" | blux savscrip save --title "cli template" --open
blux savscrip list
blux savscrip show 1
blux savscrip rename 1 "better-name"
blux savscrip move 1 ~/myproject/snippets/
```

## Plugin explorer
```python
blux plug list --long
blux plug info savscrip
blux plug open libf-save
blux plug menu
```

---

# Create Your Own Plugin

- Start from the template in plugins/_template.py:
```python
import click

def register(cli):
    @cli.group(name="myplug")
    def myplug():
        """My plugin."""
        pass

    @myplug.command("hello")
    @click.option("--name", default="world")
    def hello(name):
        click.echo(f"Hello, {name}!")
```

Save as plugins/myplug.py and run:
```python
blux --help       # 'myplug' appears in the command list
blux myplug hello --name Jadis
```

---

# Tips for Plugin Authors

- Imports — Use public helpers from blux/ (e.g., settings.py, models.py, memory.py, engines.py, router.py, utils.py).

- Graceful failure — Catch exceptions and print helpful errors.

- Startup speed — Avoid heavy work at import time; perform work inside subcommands.

- User feedback — For long-running tasks, stream output and show progress.

- Documentation — Include a clear module docstring; blux plug will display it in the plugin explorer.



---

---

## ✅ Release Status

This build of **BLUX Lite GOLD v1.0.0** has passed all automated AI-based validation:
- Full Python syntax checks
- Shell script hardening and execution scans
- Dry-run and static analysis reports

It is now **open for human testing**.

👉 Please report any errors, feedback, or comments through the Issues section of this repository.

⚠️ Note: I have worked on this project independently for over 8 months, and you may occasionally encounter errors that were missed. Please report them so they can be addressed.

---