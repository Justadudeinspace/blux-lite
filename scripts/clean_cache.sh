#!/usr/bin/env bash
# BLUX Lite GOLD — cache cleaner (dry-run by default)
# Safe: preserves configs, logs, and LibF history; scopes to repo & ~/.config/blux-lite-gold caches.

set -euo pipefail

# -------- SETTINGS --------
DRY_RUN=1     # 1 = show what would be removed; 0 = actually remove
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Sanity check: ensure we're in the BLUX-Lite repo (look for one of our known files)
[[ -f "$REPO_ROOT/blux-lite.sh" || -f "$REPO_ROOT/first_start.sh" || -f "$REPO_ROOT/README.md" ]] || {
  echo "[ABORT] Not in BLUX-Lite repo root."; exit 1;
}

echo "[INFO] Repo root: $REPO_ROOT"
echo "[INFO] DRY_RUN=$DRY_RUN (set to 0 to actually delete)"

# -------- TARGETS (Repo-local) --------
# Python / build caches
repo_patterns=(
  "__pycache__"
  ".pytest_cache"
  ".mypy_cache"
  ".ruff_cache"
  "htmlcov"
  "build"
  "dist"
)
repo_globs=(
  "*.pyc"
  "*.pyo"
  "*.coverage*"
  "coverage.xml"
  "*.egg-info"
  ".ipynb_checkpoints"
  ".DS_Store"
)

# -------- TARGETS (User cache dirs for BLUX-Lite-GOLD) --------
# We only touch cache/tmp, NEVER configs or history.
user_cache_dirs=(
  "$HOME/.config/blux-lite-gold/cache"
  "$HOME/.config/blux-lite-gold/tmp"
  "$HOME/.config/blux-lite-gold/sessions"
)

# LibF: preserve history; only clear tmp if present
libf_dirs=(
  "$HOME/.libf/tmp"
  "$HOME/.libf/cache"
)

remove_paths=()

# Collect repo-local dirs
while IFS= read -r -d '' p; do remove_paths+=("$p"); done < <(
  cd "$REPO_ROOT" && \
  find . -type d \( $(printf -- '-name %q -o ' "${repo_patterns[@]}") -false \) -print0
)

# Collect repo-local files
while IFS= read -r -d '' p; do remove_paths+=("$p"); done < <(
  cd "$REPO_ROOT" && \
  find . -type f \( $(printf -- '-name %q -o ' "${repo_globs[@]}") -false \) -print0
)

# Collect user cache dirs (only if they exist)
for d in "${user_cache_dirs[@]}" "${libf_dirs[@]}"; do
  [[ -e "$d" ]] && remove_paths+=("$d")
done

# Deduplicate
mapfile -t remove_paths < <(printf "%s\n" "${remove_paths[@]}" | awk '!seen[$0]++')

echo "[PLAN] The following paths match cache patterns:"
printf '  %s\n' "${remove_paths[@]:-<none>}"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "[DRY RUN] Nothing deleted. Re-run with DRY_RUN=0 to apply:"
  echo "  DRY_RUN=0 bash scripts/clean_cache.sh"
  exit 0
fi

# Apply deletion
for p in "${remove_paths[@]}"; do
  if [[ -e "$p" ]]; then
    rm -rf -- "$p"
    echo "[REMOVED] $p"
  fi
done

echo "[DONE] Cache cleanup complete (configs & history preserved)."
