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

# Cloud Helpers (Optional)

These are **examples** only and are **disabled by default** in public releases.

To enable:
1. Copy any needed script from here into your local environment.
2. Create a `.env` at repo root (based on `.env.example`).
3. Export `BLG_ENABLE_CLOUD=1` before running.
4. Never commit secrets.



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