# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: savscrip (enhanced)
Save LLM-generated code/output as timestamped Markdown files under ~/savscrps (by default)
for easy renaming & moving later.

New helpers:
  --open            : open the file after saving (xdg-open / open / termux-open)
  auto-tagging      : adds tags based on detected language(s)
  --lang            : manually set language tag (overrides auto)
"""
import os, sys, re, shutil, datetime, subprocess
from pathlib import Path
import click

DEFAULT_DIR = Path(os.getenv("HOME", "~")).expanduser() / "savscrps"

# --------------- language detection ---------------
LANG_HINTS = [
    (
        "python",
        [
            r"(?m)^def\s+\w+\(",
            r"(?m)^class\s+\w+\(",
            r"(?m)^\s*import\s+\w+",
            r"#!/.*python",
        ],
    ),
    ("bash", [r"(?m)^#!/bin/(ba)?sh", r"(?m)^\s*sudo\s", r"(?m)^\s*apt(-get)?\s"]),
    ("zsh", [r"(?m)^#!/bin/zsh"]),
    ("powershell", [r"(?i)\b(Set-Item|Get-ChildItem|Write-Host)\b"]),
    (
        "javascript",
        [r"(?m)\bfunction\s+\w+\(", r"(?m)=>\s*{", r"(?m)^\s*import\s+.*from\s+['\"]"],
    ),
    ("typescript", [r"(?m):\s*\w+\s*(=|;|\))", r"(?m)^\s*import\s+.*from\s+['\"]"]),
    ("json", [r"(?s)^\s*\{.*\}\s*$"]),
    ("yaml", [r"(?m)^\s*[\w\-]+\s*:\s*.+$"]),
    ("html", [r"(?si)<html\b", r"(?si)<div\b", r"(?si)</\w+>"]),
    ("css", [r"(?m)^\s*\.\w+\s*\{", r"(?m)^\s*@media"]),
    ("sql", [r"(?i)\bSELECT\b.+\bFROM\b", r"(?i)\bCREATE\s+TABLE\b"]),
    ("java", [r"(?m)^\s*public\s+class\s+\w+", r"System\.out\.println"]),
    ("kotlin", [r"(?m)^\s*fun\s+\w+\(", r"\bval\s+\w+\s*="]),
    ("rust", [r"(?m)^\s*fn\s+\w+\(", r"println!\("]),
    ("go", [r"(?m)^\s*func\s+\w+\(", r"(?m)^\s*package\s+\w+"]),
    ("cpp", [r"#include\s*<\w+>", r"\bstd::\w+"]),
    ("c", [r"#include\s*<\w+>", r"\bprintf\s*\("]),
    ("swift", [r"(?m)^\s*func\s+\w+\(", r"\blet\s+\w+\s*="]),
    ("ruby", [r"(?m)^\s*def\s+\w+\s*$", r"\bputs\s+['\"]"]),
    ("php", [r"<\?php", r"\becho\s+['\"]"]),
    ("dockerfile", [r"(?mi)^\s*FROM\s+\w", r"(?mi)^\s*RUN\s+\w"]),
]


def detect_languages(text: str):
    langs = set()
    # Prefer fenced blocks with hints: ```python
    for m in re.finditer(r"```([a-zA-Z0-9_+-]+)?\n", text):
        if m.group(1):
            langs.add(m.group(1).lower())
    # Heuristic fallback
    sample = text[:5000]
    for lang, pats in LANG_HINTS:
        for pat in pats:
            if re.search(pat, sample):
                langs.add(lang)
                break
    return sorted(langs)[:3]  # cap to 3


# --------------- core utils ---------------
def _ensure_dir(p: Path) -> Path:
    p = p.expanduser()
    p.mkdir(parents=True, exist_ok=True)
    return p


def _slugify(s: str) -> str:
    s = s.strip().lower()
    s = re.sub(r"[^\w\s-]+", "", s)
    s = re.sub(r"[\s_-]+", "-", s).strip("-")
    return s or "untitled"


def _timestamp() -> str:
    return datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")


def _list_markdowns(root: Path):
    root = root.expanduser()
    return sorted([p for p in root.glob("*.md") if p.is_file()])


def _read_stdin_if_piped() -> str:
    try:
        if not sys.stdin.isatty():
            return sys.stdin.read()
    except Exception:
        pass
    return ""


def _open_file(path: Path):
    # Cross-platform opener: termux-open, xdg-open (Linux), open (macOS)
    cmds = []
    if shutil.which("termux-open"):
        cmds = ["termux-open", str(path)]
    elif shutil.which("xdg-open"):
        cmds = ["xdg-open", str(path)]
    elif shutil.which("open"):
        cmds = ["open", str(path)]
    if cmds:
        try:
            subprocess.Popen(cmds, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass


def _write_md(dirpath: Path, title: str, body: str, tags=(), langs=()):
    dirpath = _ensure_dir(dirpath)
    slug = _slugify(title)
    name = f"{_timestamp()}__{slug}.md"
    path = dirpath / name
    all_tags = list(dict.fromkeys([*(langs or ()), *tags]))  # de-dup, preserve order
    header = [
        "---",
        f"title: {title}",
        f"date: {datetime.datetime.now().isoformat(timespec='seconds')}",
        f"tags: [{', '.join(all_tags)}]" if all_tags else "tags: []",
        "---",
        "",
    ]
    text = "\n".join(header) + body.rstrip() + "\n"
    path.write_text(text, encoding="utf-8")
    return path


def _resolve_target(dirpath: Path, key: str) -> Path:
    dirpath = dirpath.expanduser()
    items = _list_markdowns(dirpath)
    if not items:
        raise click.ClickException(f"No files in {dirpath}")
    if re.fullmatch(r"\d+", key):
        idx = int(key) - 1
        if idx < 0 or idx >= len(items):
            raise click.ClickException("Index out of range.")
        return items[idx]
    for p in items:
        if p.name == key or p.name.startswith(key):
            return p
    raise click.ClickException(f"No match for {key!r}")


# --------------- CLI ---------------
def register(cli):
    @cli.group(
        name="savscrip",
        help="Save & curate LLM code/output into timestamped Markdown files.",
    )
    def group():
        pass

    @group.command("save")
    @click.option(
        "--title",
        "-t",
        default="saved-output",
        help="Title used in filename/front-matter",
    )
    @click.option(
        "--dir",
        "dirpath",
        default=str(DEFAULT_DIR),
        help="Destination directory (default: ~/savscrps)",
    )
    @click.option(
        "--file",
        "file_in",
        type=click.Path(exists=True, dir_okay=False),
        default=None,
        help="Read from file instead of STDIN",
    )
    @click.option(
        "--tag", "tags", multiple=True, help="Add one or more tags to front-matter"
    )
    @click.option(
        "--lang", "lang", default="", help="Manually set language tag (overrides auto)"
    )
    @click.option(
        "--open", "open_after", is_flag=True, help="Open the saved file after writing"
    )
    def save(title, dirpath, file_in, tags, lang, open_after):
        """Save from STDIN (or --file) into Markdown; auto-tag language; optionally open it."""
        content = ""
        if file_in:
            content = Path(file_in).read_text(encoding="utf-8", errors="ignore")
        else:
            content = _read_stdin_if_piped()
            if not content:
                raise click.ClickException(
                    "Nothing to save: pipe data in, or use --file."
                )

        # ensure fenced code block if it looks like code but isn't fenced
        if "```" not in content and re.search(
            r"(?m)^(def |class |#include|import |package |SELECT |function |FROM )",
            content,
        ):
            content = "```text\n" + content.rstrip() + "\n```\n"

        langs = [lang] if lang else detect_languages(content)
        out = _write_md(Path(dirpath), title, content, tags=tags, langs=langs)
        click.echo(str(out))
        if open_after:
            _open_file(out)

    @group.command("list")
    @click.option("--dir", "dirpath", default=str(DEFAULT_DIR))
    def list_cmd(dirpath):
        items = _list_markdowns(Path(dirpath))
        if not items:
            click.echo("(empty)")
            return
        for i, p in enumerate(items, 1):
            click.echo(f"{i:>3}. {p.name}")

    @group.command("show")
    @click.argument("key")
    @click.option("--dir", "dirpath", default=str(DEFAULT_DIR))
    def show_cmd(key, dirpath):
        path = _resolve_target(Path(dirpath), key)
        click.echo(path.read_text(encoding="utf-8", errors="ignore"))

    @group.command("rename")
    @click.argument("key")
    @click.argument("new_title")
    @click.option("--dir", "dirpath", default=str(DEFAULT_DIR))
    def rename_cmd(key, new_title, dirpath):
        path = _resolve_target(Path(dirpath), key)
        ts = path.name.split("__", 1)[0]
        new_name = f"{ts}__{_slugify(new_title)}.md"
        new_path = Path(dirpath).expanduser() / new_name
        path.rename(new_path)
        click.echo(str(new_path))

    @group.command("move")
    @click.argument("key")
    @click.argument("dest", type=click.Path(file_okay=False))
    @click.option("--dir", "dirpath", default=str(DEFAULT_DIR))
    def move_cmd(key, dest, dirpath):
        path = _resolve_target(Path(dirpath), key)
        destp = Path(dest).expanduser()
        destp.mkdir(parents=True, exist_ok=True)
        new_path = destp / path.name
        path.rename(new_path)
        click.echo(str(new_path))

    @group.command("cleanup")
    @click.option(
        "--older-than-days",
        type=int,
        default=0,
        help="Delete files older than N days (0 = no-op)",
    )
    @click.option("--dir", "dirpath", default=str(DEFAULT_DIR))
    def cleanup_cmd(older_than_days, dirpath):
        if older_than_days <= 0:
            click.echo("Nothing to clean (use --older-than-days N)")
            return
        cutoff = datetime.datetime.now() - datetime.timedelta(days=older_than_days)
        root = Path(dirpath).expanduser()
        count = 0
        for p in _list_markdowns(root):
            ts_part = p.name.split("__", 1)[0]
            try:
                ts = datetime.datetime.strptime(ts_part, "%Y-%m-%d_%H%M%S")
            except Exception:
                continue
            if ts < cutoff:
                try:
                    p.unlink()
                    count += 1
                except Exception:
                    pass
        click.echo(f"Deleted {count} files older than {older_than_days} days.")
