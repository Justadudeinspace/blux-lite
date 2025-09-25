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

### **preinstall_hf.sh**
- Prepares your system for Hugging Face model downloads.

> **What it does:**
- Installs `git`, `git-lfs`, `openssh`, and Python if missing.
- Installs `huggingface_hub[hf]` CLI and `hf-transfer` (for faster downloads).
- Generates an SSH key for `hf.co` if needed.
- Optionally logs in with `HF_TOKEN` (non-interactive).

## **Usage:**
```bash
bash preinstall_hf.sh
# or with HF_TOKEN
HF_TOKEN="hf_xxx" bash preinstall_hf.sh
```

- Run from anywhere:
```bash
bash ~/blux-lite/scripts/preinstall_hf.sh
```

---

# diagnostics.sh

- Runs a quick environment check for BLUX Lite.

> What it checks:

> OS, shell, Python, Pip versions.

> git, curl, Hugging Face CLI presence.

> Current HF login status.

> Local llama binary and models directory.

> Disk usage and free space.


## Usage:
```bash
bash diagnostics.sh
```

- Run from anywhere:
```bash
bash ~/blux-lite/scripts/diagnostics.sh
```

---

# disk_check.sh

- Shows disk usage for your BLUX Lite root and lists installed models.

## Usage:
```bash
bash disk_check.sh
```

- Run from anywhere:
```bash
bash ~/blux-lite/scripts/disk_check.sh
```

---

# uninstall.sh

- Removes local engines/ and models/ folders.
- Apps, projects, and configs are left intact.

## Usage:
```bash
bash uninstall.sh
```

## Will prompt you to type REMOVE before proceeding

- Run from anywhere:
```bash
bash ~/blux-lite/scripts/uninstall.sh
```

---

# Notes

> All scripts assume the BLUX_ROOT environment variable points to your BLUX Lite install root. If unset, defaults to ~/blux-lite.

> Scripts are safe to run multiple times; they only overwrite what they manage.

> On Termux, they use pkg; on Debian/Ubuntu, they use apt.

> For convenience, you can add this to your shell config to run scripts without typing the path:

```bash
export PATH="$HOME/blux-lite/scripts:$PATH"
```

- After adding that, you can just run:
```bash
preinstall_hf.sh
diagnostics.sh
disk_check.sh
uninstall.sh
```

- from anywhere.


---

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