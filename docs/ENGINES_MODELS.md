# Engines & Models Catalog — BLUX Lite GOLD

This system provides two JSON catalogs under `.config/blux-lite-gold/catalogs/`:

- `engines.json` — runtimes (local & hosted APIs)
- `models.json` — open-weight and hosted models

## CLI

```bash
python -m blux.catalog_install engines --filter local
python -m blux.catalog_install models --filter qwen
python -m blux.catalog_install plan llama-3.1-8b
python -m blux.catalog_install apply llama-3.1-8b
```

## Menus

- **Legacy menu**: entries for listing and applying model installs.
- **TUI menu**: interactive picker using `fzf` or `gum` if available; falls back to prompt.

## Notes

- Hosted APIs require API keys (see `engines.json` entries for environment variables).
- Open-weight models include indicative Hugging Face links and Ollama tags when available.