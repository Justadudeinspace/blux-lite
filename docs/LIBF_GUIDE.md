# Liberation Framework (LIBF) Guide

BLUX‑Lite includes a lightweight **Liberation Framework (.libf)** for *project memory* and session history.
It’s designed to be simple, append‑only, and portable (plain JSONL), so you can grep, back up, and sync it easily.

---

## TL;DR

- Data root (by default): **`$HOME/blux-lite/.libf`**  ← controlled by `settings.json: libf_memory_dir` (the installer creates this).
- Each project has: **`projects/<project>/history.jsonl`** (one JSON object per line).
- You add entries with the CLI (built‑ins and plugins):
  - `blux libf-note "Short note" --text "longer details"`
  - `blux libf-save <Project> --title "Session name" --file ./session.txt` *(plugin)*
- The file **auto‑rotates** when it grows beyond `memory_max_lines` (default 5000).

---

## Directory Layout

```
$HOME/blux-lite/.libf/
└── projects/
    ├── default/
    │   └── history.jsonl
    └── MyProject/
        └── history.jsonl
```

- Root directory: taken from **`blux/settings.py → SETTINGS['libf_memory_dir']`**.
  - The **installer** writes this to `~/.config/blux-lite-gold/settings.json` as `libf_memory_dir: "$ROOT/.libf"`.
- Each project directory is created on demand.

---

## Entry Format (JSONL)

Each line in `history.jsonl` is one JSON object with (at least) these fields:

```json
{
  "ts": "2025-08-14T12:34:56",
  "project": "MyProject",
  "prompt": "Your short title or user prompt",
  "answer": "Longer body text or model output"
}
```

- Timestamps are ISO‑8601 (seconds precision).
- **prompt** and **answer** are free‑form strings. You can include front‑matter or markdown.
- You can safely append your own fields — readers ignore unknown keys.

---

## How Saves Happen (under the hood)

Relevant code:
- **`blux/memory.py`**
  - `libf_path(project) → Path`: resolves/creates the project folder and returns `history.jsonl`.
  - `_rotate_if_needed(path, max_lines=5000)`: automatically rotates if the file has more than N lines.
  - `save_memory(project, prompt, answer)`: writes an entry with `{ts, project, prompt, answer}`.
  - `list_sessions(project=None) -> List[dict]`: reads and parses all entries.
- **`blux/settings.py`**
  - Maintains `SETTINGS` with defaults; persists to `~/.config/blux-lite-gold/settings.json`.
  - Keys of interest:
    - `libf_memory_dir` (default: `$HOME/blux-lite/.libf`)
    - `project` (active project)
    - `memory_max_lines` (default: 5000)

---

## Recommended Commands

### Quick notes
```bash
blux libf-note "Meeting recap" --text "Key decisions…"
```

### Save a full session (plugin)
```bash
# From a file
blux libf-save MyProject --title "Spec v1" --file ./spec.md

# From stdin (pipe)
cat transcript.txt | blux libf-save MyProject --title "Pairing log"
```

### List recent memory
```bash
blux project sessions --last 10
```

### Programmatic read (Python)
```python
from blux.memory import list_sessions
rows = list_sessions("MyProject")
print(rows[-5:])
```

---

## Rotation Policy

To prevent unbounded growth, `save_memory()` calls `_rotate_if_needed()` before appending. The limit comes from:

- `settings.json: "memory_max_lines"` (default **5000**).

When the limit is exceeded, the file is rotated — older lines are moved aside; the current file keeps recent history. (Implementation: fast line‑count with simple keep/rotate logic.)

> If you’re keeping long research logs, consider syncing the projects directory to a cloud folder or git repo.

---

## Changing Paths & Projects

- **Active project**: `settings.json → "project"` (change via `blux project set <name>`).
- **Memory root**: `settings.json → "libf_memory_dir"` (point it to any absolute path).

The settings file lives at `~/.config/blux-lite-gold/settings.json`.

---

## Backup & Export

Because the format is JSONL, exports are easy:

```bash
# Backup one project
proj=MyProject
mkdir -p backups && cp "$HOME/blux-lite/.libf/projects/$proj/history.jsonl" "backups/${proj}_$(date +%F).jsonl"

# Convert to Markdown (titles + bodies)
python - <<'PY'
import json, sys
for line in open(sys.argv[1], encoding="utf-8"):
    row = json.loads(line)
    print(f"## {row.get('ts')} — {row.get('prompt','')}
")
    print(row.get('answer',''), "\n")
PY "$HOME/blux-lite/.libf/projects/$proj/history.jsonl" > "${proj}.md"
```

---

## Security & Privacy

- Entries may include model outputs and PII. Treat the `.libf` folder as **private**.
- The framework does **not** phone home. It writes to local disk only.
- If you need encryption, keep the `.libf` directory on an encrypted volume or use OS‑level encryption.

---

## Troubleshooting

- “No such file or directory”: run a save command once (directories are created on demand).
- “Nothing to save”: `libf-save` reads **stdin** unless `--file` is passed.
- “Missing project”: project folders are created automatically when saving.

---

## FAQ

**Q: Can I add custom metadata?**  
Yes. Add more keys to the `entry` dict if you write via Python; the reader ignores extra fields.

**Q: Can I merge multiple history files?**  
Yes. Concatenate JSONL files in chronological order; rotation does not change the schema.

**Q: Where do I change the history length?**  
Edit `~/.config/blux-lite-gold/settings.json → "memory_max_lines"`.


---

## See Also

- `plugins/libf_save.py` — save full sessions to a project (stdin or file).
- `plugins/libf_note.py` — append short notes.
- `plugins/project.py` — show/set the active project and list sessions.