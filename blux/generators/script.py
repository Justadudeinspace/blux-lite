from __future__ import annotations
from textwrap import dedent


def bash_script_skeleton(path: str, title: str | None = None) -> str:
    title = title or path
    return dedent(
        f"""
#!/usr/bin/env bash
# path: {path}
set -euo pipefail
IFS=$'\n\t'

echo "{title}"
"""
    )
