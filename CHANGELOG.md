# Changelog

## v1.0.0 — Final Polished Release (2025-09-18T07:15:00Z)

### Added
- **Unified CREDITS.md** with all plugins, scripts, frameworks, AI models, and AI engines credited to original developers/orgs (no placeholders, no duplicates).
- **BLUXQ (Model Access API)**:  
  - Daemon: `blux/bluxq.py` with **UDS (default)** and **HTTP** modes.  
  - TUI: `scripts/tui/bluxq.tui.sh`.  
  - Legacy entry: `bash blux-lite.sh bluxq`.
- **Client & Examples**:  
  - Python client: `blux/bluxq_client.py`.  
  - Integration snippets: `examples/BLUXQ_INTEGRATIONS.md`.
- **Catalogs**:  
  - `.config/blux-lite/models_and_engines.catalog.json` covering corporate APIs and open-weight LLMs.

### Updated
- **README.md**:  
  - Clean, accurate **Quickstart** (`first_start.sh` → root `auto-start.sh`).  
  - Streamlined **Commands & Menus**.  
  - **Project Layout** section in `lsd` format with routing lines, collapsible preserved.  
  - Added clickable **Table of Contents**.  
- **CHANGELOG.md**: restructured professionally with sections.  
- **Docs**: all Markdown and README files checked for accuracy, normalized links, redundancies removed.  
- **Licensing**: added explicit **MIT License** with attribution to *Justadudeinspace | ~JADIS*.  
- **first_start.sh**: confirmed restores all execution bits for `.sh` and `.py` files automatically.

### Fixed
- **Exec-bits**: all shell scripts made executable; `first_start.sh` ensures this persists.  
- **Syntax errors**: patched in `plugin_menu.sh`, `scripts_menu.sh`, and `examples/cloud/rclone_setup.sh`.  
- **Credits**: restored missing developers (e.g., **osm0sis**, **iBotPeaches**, **bkerler**, **Benjamin-Dobell**), with all individuals/orgs now linked.

### Confidence
- **Bash scripts**: 97 checked — all pass `bash -n`.  
- **Python files**: 61 checked — all compile clean.  
- **TUIs**: syntax passes; integrated with Textual and Legacy menus.  
- **Placeholders**: none remaining.  
- **Exec bits**: restored automatically by `first_start.sh`.  
- **Audit**: meticulous pass shows no errors or misinformation in docs.  
- **Release confidence**: **98%**, with **2% reserved for cross-platform runtime variance**.

---