# Storage Guide

This guide explains where BLUX‑Lite stores models, binaries, and **Liberation Framework (.libf)** data,
and how to place them for the best performance across platforms.

_Last updated: 2025-08-14T18:54:26_

## Defaults (from `blux/settings.py`)
- **models_dir**: strPathos.getenvBLUX_MODELS_DIR
- **bin_dir**: strPathos.getenvBLUX_BIN_DIR
- **libf_memory_dir**: strPathos.getenvBLUX_LIBF_DIR
- **libf_projects_dir**: defined in settings
- **cache_dir**: defined in settings

> You can override these in your settings file or via environment variables if supported by your build.

## Storage Layout
```
blux-lite (repo root)
├─ bin → strPathos.getenvBLUX_BIN_DIR (symlinks/wrappers)
├─ models → strPathos.getenvBLUX_MODELS_DIR (*.gguf, catalogs)
├─ libf/memory → strPathos.getenvBLUX_LIBF_DIR (*.jsonl default project store)
└─ plugins
   ├─ exports/ (e.g., libf-export output)
   └─ savscrip → ~/savscrps (saved code as .md)
```

## Platform Notes
- **Android / Termux**
  - Use **internal storage** for `.gguf` (fast I/O). External SD cards are often too slow.
  - Open files with `termux-open` / URLs with `termux-open-url`.
  - Keep `models_dir` under `~/blux-lite/models` or another internal path.
- **Linux (Debian/Ubuntu) & WSL2**
  - Keep models on native Linux FS (e.g., `~/blux-lite/models`) — avoid Windows mount (`/mnt/c/...`) for speed.
  - Use `xdg-open` for opening files/URLs.
- **macOS**
  - Use internal SSD paths (e.g., `~/blux-lite/models`).
  - `open` is used for files/URLs (installer detects it).

## Best Practices
- Prefer **fast storage** (internal SSD / internal phone storage).
- Pick **quantizations** that fit RAM: start with Q4_K_M; go up/down as needed.
- Use the **catalog** plugin to fetch curated GGUFs (`blux catalog list`, `download`).
- For limited storage, run in **API‑only mode** (OpenAI‑compatible / HF Inference).
- Keep `.jsonl` histories under `libf/projects/<Project>/history/` small by exporting/archiving regularly.
- Back up your `.libf` projects; they are append‑only logs of your work and prompts.
- Avoid storing models on slow external media; it will bottleneck token generation.

## Model Sizing & Placement
- Tiny (≤2B): 0.5–2 GB files → OK on low‑RAM devices; keep on fast internal storage.
- Small (3–4B): 3–6 GB → good for laptops/phones with 6–8 GB RAM.
- Mid (7–8B): 7–12 GB → needs 12–16 GB RAM.
- Large (10–14B): 12–20 GB → needs 16–24 GB RAM.

Use **`docs/MODELS_TABLE.md`** for RAM tiers and quant suggestions per model.

## .libf (Liberation Framework) Data
- Project histories live under: `~/<blux-lite>/libf/projects` in `history/*.jsonl` (append‑only).
- Default project memory file is under: `strPathos.getenvBLUX_LIBF_DIR`.
- Save arbitrary session text via: `blux libf-save <Project> --title "..."` (see `plugins/libf_save.py`).
- Export histories with: `blux libf-export <Project> --format md|json [--since —-MM-DD] [--until —-MM-DD] [--tag TAG]`.

## Plugin Storage
- **savscrip**: saves timestamped Markdown to `~/savscrps` (`blux savscrip save --title ...`).
- **libf-export**: outputs to `./exports/<project>.md` or a path of your choosing (`--out`).
- **plug**: reads plugin files from `~/blux-lite/plugins`.

## Tips for Low Storage Environments
- Use APIs for larger models; only keep a **tiny** local model for offline emergencies.
- Periodically **archive** old `.libf` history lines (via `libf-export`) and **prune** with date filters.
- Verify **symlinks** in `bin/` point to the right engine binaries; keep only what you use.

---

### FAQ
**Q:** Can I put models on an SD card?  
**A:** You can, but expect slower generations. Prefer internal storage/SSD.

**Q:** How do I move my models folder?  
**A:** Move the directory, update `models_dir` in settings, and fix any symlinks in `bin/` if needed.

**Q:** Do you support multiple model folders?  
**A:** Use per‑project configs or environment overrides to point to different `models_dir` values.

**Q:** How big should my `.libf` history be?  
**A:** Keep it lean—export and archive regularly. Extremely large JSONL files can slow down tooling.