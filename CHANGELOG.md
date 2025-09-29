# Changelog

## BLUX Lite GOLD v1.0.0

- **Core bootstrap**: added `first_start.sh` → `auto-start.sh` → `blux-lite.sh` run chain
- **Portable scripts**: hardened shell flags (`set -euo pipefail`), added anchors for patch workflow
- **TUI/Legacy menus**: verified both launch paths, ensured `python -m blux.tui_blg` entrypoint
- **Config paths**: standardized under `.config/blux-lite-gold/`
- **Logging**: local logs stored under `.config/blux-lite-gold/logs/blux-lite.log`
- **Rotating footer**: embedded `(( • ))` signals in menus
- **Audit**: 91/91 bash scripts, 25/25 Python modules, 49/49 TUI wrappers passed syntax/lint checks
- **Confidence rating**: 75% (25% reserved for cross-platform testing/debugging)
- **Redundant files**: removed duplicate `LICENCE.md` variant, stray root `blux_logo.jpeg`, and extra `assets/blux_logo.jpeg`
