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

# BLUX-Lite Documentation

Welcome to the BLUX-Lite documentation hub.  
This section indexes all guides, quick starts, and reference tables for the project.

---

## 📜 Quick Start Guides
Choose the guide that matches your platform or hardware:

- [Quick Start — Mobile (Low RAM)](Quick_Start_Mobile_Low_RAM.md)
- [Quick Start — Mobile (Normal)](Quick_Start_Mobile_Normal.md)
- [Quick Start — Mobile (High-End)](Quick_Start_Mobile_High_End.md)
- [Quick Start — Linux](Quick_Start_Linux.md)
- [Quick Start — Windows](Quick_Start_Windows.md)
- [Quick Start — macOS](Quick_Start_macOS.md)

---

## 📂 Core Guides
- [STORAGE_GUIDE.md](STORAGE_GUIDE.md) — Default paths, storage layout, and performance tips.
- [LIBF_GUIDE.md](LIBF_GUIDE.md) — Liberation Framework usage, data format, rotation, and commands.

---

## 📊 Reference Tables
- [MODELS_TABLE.md](MODELS_TABLE.md) — Model catalog with RAM tiers, quant suggestions, and links.
- [ENGINES_TABLE.md](ENGINES_TABLE.md) — Engines, detection, RAM tiers, quant suggestions, links, and build commands.

---

## 🧩 Plugins
- See [`../plugins/README.md`](../plugins/README.md) for available plugins, usage, and how to create your own.
- Notable built-in plugins:
  - **savscrip** — Save code output as Markdown in a dedicated folder.
  - **libf-save** — Store current session in a `.libf` project.
  - **libf-export** — Export `.libf` histories to Markdown or JSON.
  - **plug** — Browse and manage plugins interactively.

---

## 📌 Tips
- For installation instructions, see the root [`README.md`](../README.md) and [`blux-lite_installer.sh`](../blux-lite_installer.sh).
- Use the [Storage Guide](STORAGE_GUIDE.md) to decide where to keep models and data for best performance.

---

_Last updated: 2025-08-14_

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