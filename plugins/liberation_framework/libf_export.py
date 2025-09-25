# -*- coding: utf-8 -*-
"""
BLUX Lite Plugin: libf-export

Export a project's Liberation Framework history to **Markdown** or **JSON**.
Supports date and tag filters.

Usage:
  # Markdown export (default filename under ./exports/)
  blux libf-export myproj --format md

  # JSON export to a specific file
  blux libf-export myproj --format json --out ./myproj-history.json

  # Filter by date range (inclusive) and tags
  blux libf-export myproj --since 2025-08-01 --until 2025-08-14 --tag coding --tag plan --format md

Notes:
- Reads history JSONL via blux.memory.libf_path(project).
- Each line is a JSON object with at least: ts, prompt, answer (as produced by save_memory).
- Tag filtering looks for a YAML-ish front-matter header embedded in 'answer' (if present):
    ---
    meta: {"tags":["coding","plan"], ...}
    ---
  If no header, tag filtering is skipped for that entry.
"""
import json, re, sys, os, datetime
from pathlib import Path
import click
from blux.memory import libf_path
from blux.settings import SETTINGS

DATE_FMT = "%Y-%m-%d"


def _parse_date(s):
    try:
        return datetime.datetime.strptime(s, DATE_FMT).date()
    except Exception:
        raise click.ClickException(f"Invalid date '{s}'. Expected YYYY-MM-DD.")


def _load_entries(project: str):
    path = Path(libf_path(project)).expanduser()
    if not path.exists():
        return []
    rows = []
    with path.open("r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                rows.append(obj)
            except Exception:
                continue
    return rows


FM_RE = re.compile(r"^---\s*?\nmeta:\s*(\{.*?\})\s*?\n---\s*?\n", re.S)


def _extract_tags(answer: str):
    if not isinstance(answer, str):
        return []
    m = FM_RE.match(answer)
    if not m:
        return []
    try:
        meta = json.loads(m.group(1))
        return list(meta.get("tags", [])) if isinstance(meta, dict) else []
    except Exception:
        return []


def _filter(entries, since, until, tags):
    def ok(row):
        ts = row.get("ts") or row.get("timestamp") or ""
        try:
            d = datetime.datetime.fromisoformat(ts.replace("Z", "")).date()
        except Exception:
            d = None
        if since and d and d < since:
            return False
        if until and d and d > until:
            return False
        if tags:
            found = set(_extract_tags(row.get("answer", "")))
            if not set(tags).issubset(found):
                return False
        return True

    return [r for r in entries if ok(r)]


def _to_markdown(project: str, rows):
    lines = [f"# .libf Export — {project}", ""]
    for r in rows:
        ts = r.get("ts") or r.get("timestamp") or ""
        prompt = r.get("prompt", "").strip()
        answer = r.get("answer", "").rstrip()
        lines.append(f"## {ts}")
        if prompt:
            lines.append("**Prompt**")
            lines.append("")
            lines.append("```text")
            lines.append(prompt)
            lines.append("```")
            lines.append("")
        if answer:
            lines.append("**Answer**")
            lines.append("")
            # ensure a blank line before fenced blocks if not present
            if not answer.startswith("```"):
                lines.append("```text")
                lines.append(answer)
                lines.append("```")
            else:
                lines.append(answer)
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"


@click.command(name="libf-export")
@click.argument("project", required=True)
@click.option(
    "--format",
    "fmt",
    type=click.Choice(["md", "json"]),
    default="md",
    help="Export format (md/json)",
)
@click.option(
    "--out",
    "out_path",
    default="",
    help="Output file path. Defaults to ./exports/<project>.<ext>",
)
@click.option(
    "--since", default="", help="Only entries on/after this date (YYYY-MM-DD)"
)
@click.option(
    "--until", default="", help="Only entries on/before this date (YYYY-MM-DD)"
)
@click.option(
    "--tag",
    "tags",
    multiple=True,
    help="Require these tags (from front-matter meta.tags in the answer)",
)
def libf_export(project, fmt, out_path, since, until, tags):
    rows = _load_entries(project)
    if not rows:
        click.echo(f"No history for project '{project}'.")
        return
    s = _parse_date(since) if since else None
    u = _parse_date(until) if until else None
    rows = _filter(rows, s, u, list(tags))

    # Default output path
    if not out_path:
        exports_dir = Path.cwd() / "exports"
        exports_dir.mkdir(parents=True, exist_ok=True)
        ext = "md" if fmt == "md" else "json"
        out_path = exports_dir / f"{project}.{ext}"
    outp = Path(out_path)

    if fmt == "json":
        outp.write_text(
            json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
    else:
        outp.write_text(_to_markdown(project, rows), encoding="utf-8")

    click.echo(str(outp))


def register(cli):
    cli.add_command(libf_export)
