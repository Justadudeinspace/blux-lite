# `blux/` — Core Package

Core modules that power BLUX Lite GOLD (CLI, router, settings, engine/model registry).  


## Layout

<details>
<summary>Click to expand package tree</summary>

```
blux-lite-gold/
├── blux/
│   ├── orchestrator/
│   │   ├── evaluator/
│   │   ├── __init__.py
│   │   ├── classifier.py
│   │   ├── controller.py
│   │   ├── logs.py
│   │   ├── registry.py
│   │   └── router.py
│   ├── __init__.py
│   ├── cli.py
│   ├── config.py
│   ├── engines.py
│   ├── installer.py
│   ├── legacy_menu.py
│   ├── libf_loader.py
│   ├── memory.py
│   ├── models.py
│   ├── plugins.py
│   ├── README.md
│   ├── router.py
│   ├── secrets.py
│   ├── settings.py
│   ├── tui_blg.py
│   ├── tui_blg.tcss
│   ├── utils.py
│   └── version.py
├── docs/
│   ├── assets/
│   │   ├── blux-lite-banner.png
│   │   └── blux-wiki-footer.svg
│   ├── BLUX-LITE-GOLD-FILETREE.md
│   ├── CMD_HELP.md
│   ├── LIBF_GUIDE.md
│   ├── QUICKSTART_HIGH_END.md
│   ├── QUICKSTART_LINUX.md
│   ├── QUICKSTART_LOW_RAM.md
│   ├── QUICKSTART_MACOS.md
│   ├── QUICKSTART_NORMAL.md
│   ├── QUICKSTART_WINDOWS.md
│   ├── README.md
│   └── STORAGE_GUIDE.md
├── engines/
│   ├── engines_catalog.json
│   └── README.md
├── heart/
│   └── index.html
├── libf/
│   ├── projects/
│   │   └── README.md
│   ├── libf_public_framework.zip
│   └── README.md
├── models/
│   ├── catalog_full.json
│   └── README.md
├── plugins/
│   ├── liberation_framework/
│   │   ├── libf_export.py
│   │   ├── libf_hub.py
│   │   ├── libf_note.py
│   │   ├── libf_save.py
│   │   └── project.py
│   ├── _template.py
│   ├── aik_mobile.py
│   ├── android_recipes.py
│   ├── android_sdk.py
│   ├── apk_retool.py
│   ├── apktool_plugin.py
│   ├── bench.py
│   ├── buildtools_signalign.py
│   ├── catalog.py
│   ├── code_quality.py
│   ├── community_fetcher.py
│   ├── compat_scan.py
│   ├── daisy_of_jadis.py
│   ├── doctor.py
│   ├── dtc_tools.py
│   ├── engines_plus.py
│   ├── genkit.py
│   ├── gguf_tools.py
│   ├── heimdall_tools.py
│   ├── lora_manager.py
│   ├── modpacks.py
│   ├── mtkclient_plugin.py
│   ├── payload_tools.py
│   ├── plug.py
│   ├── README.md
│   ├── recipes.py
│   ├── rom_manager_safe.py
│   ├── router_debug.py
│   ├── savscrip.py
│   └── sys.py
├── scripts/
│   ├── cloud/
│   │   ├── admin.sh
│   │   ├── blux_cloud_safety_addon.sh
│   │   ├── heart.sh
│   │   ├── kill_switch.sh
│   │   ├── selftest.sh
│   │   └── snapshot.sh
│   ├── main_menu/
│   │   ├── auto_start_all.py
│   │   ├── auto_start_all.sh
│   │   ├── catalog.sh
│   │   ├── env.sh
│   │   ├── fzf_env.sh
│   │   ├── install_blux_shiv.sh
│   │   ├── install_deps.sh
│   │   ├── load_secrets.sh
│   │   ├── logging.sh
│   │   ├── preinstall_hf.sh
│   │   └── validate_secrets.sh
│   ├── adb_helper.sh
│   ├── aliases_install.sh
│   ├── backup_blux.sh
│   ├── blg_tui.sh
│   ├── blux_autostart_boot.sh
│   ├── blux_box86_wine.sh
│   ├── blux_freshtermux.sh
│   ├── blux_proot_arch.sh
│   ├── blux_services_setup.sh
│   ├── blux_simple_tar_backup.sh
│   ├── blux_styling_apply.sh
│   ├── blux_widget_shortcut.sh
│   ├── diagnostics.sh
│   ├── disk_check.sh
│   ├── docs-cli.sh
│   ├── flashing_helper.sh
│   ├── install_power_tools.sh
│   ├── logs_rotate.sh
│   ├── rclone_setup.sh
│   ├── README.md
│   ├── remove_engs_and_mods.sh
│   ├── restore_blux.sh
│   ├── run_shellcheck.sh
│   ├── setup_termux_api.sh
│   ├── starship_setup.sh
│   ├── termux_boot_enable_blux.sh
│   ├── update_all.sh
│   └── wifi_battery_info.sh
├── shim/
│   └── launcher.py
├── tests/
│   └── manifest.json
├── .gitignore
├── blux-lite.sh
├── blux.py
├── first_start.sh
├── plugin_menu.sh
├── pyproject.toml
├── README.md
├── requirements.txt
└── scripts_menu.sh
```

</details>

### Key modules
- `cli.py` — command‑line interface (`python -m blux.cli`)
- `router.py` — selects active engine/model based on `.config/blux-lite/router.yaml`
- `engines.py` / `models.py` — registries used by the router
- `settings.py` — environment/config resolution (reads `.secrets/secrets.env` too)
- `memory.py` — lightweight state store
- `utils.py` — common helpers
- `secrets.py` — secret access wrappers
- `version.py` — package version

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

### Requirements
- **bash** (>= 4.0)
- Standard Unix tools: **coreutils**, **findutils**, **grep**, **sed**, **tar**
- Python 3.x


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


### Optional Cloud Integrations (Disabled by Default)
Cloud helpers and personal secret loaders have been moved to `examples/cloud/`. 
They are **off by default** for public releases. To enable, copy the relevant example, create a local `.env` with your own keys, and set `BLG_ENABLE_CLOUD=1`. Never commit secrets.