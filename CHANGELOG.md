# Changelog

## v1.0.0 — Final Polished Release (2025-09-27T00:00:00Z)

### Added
- **Rotating Footer Signals**: embedded across Legacy/TUI menus with the `(( • ))` word-signal rotation.
- **Audit Reports**: included pass/fail summaries for Python, Bash, and TUI wrappers in `docs/`.
- **Standardized Config Path**: `.config/blux-lite-gold/` enforced across scripts, docs, and auto-start chain.
- **Assets**: consolidated under `docs/assets/` (banner, footer, logo).

### Updated
- **README.md**:  
  - File tree refreshed to reflect final v1.0.0 structure.  
  - Highlights updated with rotating footer signals.  
  - Config notes corrected to `.config/blux-lite-gold/`.  
  - License section clarified (MIT canonical only).
- **CHANGELOG.md**: entry updated to September 27th with all fixes.  
- **Docs**: broken relative links fixed; typo’d `architecture. md` renamed to `architecture.md`.  
- **Scripts**: all `.sh` files updated with strict flags (`set -euo pipefail`, `IFS=$'\n\t'`), normalized shebangs (`#!/usr/bin/env bash`).

### Fixed
- **Redundant files**: removed duplicate `LICENSE.md`/`LICENCE*` variants, stray root `blux_logo.jpeg`, and extra `assets/blux_logo.jpeg`.  
- **Exec-bits**: ensured all shell scripts are executable; verified by audit.  
- **Broken Markdown links**: resolved across docs.  
- **Consistency**: eliminated mixed `.config/blux-lite/` vs `.config/blux-lite-gold/` references.

### Confidence
- **Bash scripts**: all pass `bash -n`, strict mode enforced, exec bits present.  
- **Python files**: compile clean; key entrypoints validated.  
- **TUIs**: wrappers smoke-tested; functional coverage still minimal but no syntax errors.  
- **Docs**: consistent, no misinformation, cleaned duplicates.  
- **Release confidence**: **75%**, with **25% reserved for cross-platform runtime variance**.

---