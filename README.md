
<p align="center">
  <img src="docs/assets/blux-lite-banner.png" alt="BLUX Lite" width="100%">
</p>

<h1 align="center">BLUX Lite GOLD</h1>
<p align="center"><em>Personal AI orchestrator for trust, sovereignty, and speed.</em></p>

<p align="center">
  <img alt="Ubuntu/Debian Recommended" src="https://img.shields.io/badge/Ubuntu%2FDebian-Recommended-blue">
  <img alt="Termux Supported" src="https://img.shields.io/badge/Android%20Termux-Supported-green">
  <img alt="Windows (WSL2)" src="https://img.shields.io/badge/Windows-WSL2%20OK-lightgrey">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-Supported-lightgrey">
</p>

---

> **Ethical Preamble:** This software exists to support growth, healing, and autonomy — not harm. (( • ))

## TL;DR
- **What:** Local-first AI orchestrator (CLI + menus) to install, route, and run multiple models/engines.
- **Why:** Your data stays yours. Decisions are explainable. No black-box lock-in.
- **Where:** Linux, macOS, WSL2, Termux/Android.

## Quickstart
```bash
git clone https://github.com/Justadudeinspace/blux-lite.git && cd blux-lite
chmod +x first_start.sh && ./first_start.sh   # creates .venv, sets configs
./auto-start.sh                               # daily driver
# CLI
source .venv/bin/activate
python -m blux.cli --help
```

## Highlights

Unified shell — manage engines, models, and plugins without leaving BLUX.

Pluggable — drop tools in plugins/; catalogs plan/apply installs.

Liberation Framework (.libf) — project memory you own.

Portable — works on phone (Termux) to desktop.


## Platform	Status

> - Termux / Android	✅ Stable (primary dev)

> - Linux Distros	⚠️ Needs wider testing

> - WSL2 / Windows	⚠️ Needs wider testing

> - macOS	⚠️ Needs wider testing

> - Native MS Windows coming soon


## Do the thing
```python
python -m blux.catalog_install engines
python -m blux.catalog_install models
python -m blux.catalog_install plan llama-3.1-8b
python -m blux.ish   # integrated shell
```

## What’s inside (short)

- [blux/](./blux) — orchestrator (registry/router/controller/evaluators), CLI, TUI.

- [plugins/](./plugins) — optional tools (Android, code quality, doctor, libf, etc.). 

- [docs/](./docs) — quickstarts & guides.


> Secrets: [`.secrets/`](./.secrets) (git-ignored). Runtime config: [`.config/blux-lite-gold/`](./.config/blux-lite-gold/).



## Status (v1.0.1-pre)

✅ Run chain: first_start.sh → auto-start.sh → blux-lite.sh

✅ Python + shell syntax/lint pass

⚠️ TUI alpha — navigation rough, expect bugs

⚠️ Cross-platform coverage in progress
Issues/PRs welcome.


## Links

- **Docs & Guides:** [docs/](./docs) (per-OS quickstarts)

- **Credits:** [CREDITS.md](./CREDITS.md)

- **License:** [MIT](./LICENSE)

Story: Ashes to Code → https://github.com/Justadudeinspace/ashes-to-code


<p align="center"><em>Built mobile-first, auditable by design. Healing path only.</em><br/>(( • ))</p>

