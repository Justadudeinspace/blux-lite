from __future__ import annotations
import re
from typing import List, Dict

FENCE_RE = re.compile(r"```(?P<info>[^\n]*)\n(?P<body>.*?)```", re.S)


def _path_from_info(info: str) -> str | None:
    m = re.search(r"(path|filename)\s*=\s*([^\s]+)", info or "", re.I)
    if m:
        return m.group(2).strip()
    return None


def _path_from_body(body: str) -> str | None:
    lines = body.splitlines()[:5]
    for line in lines:
        m = re.search(r"(#|//|;|--|<!--)\s*path\s*:\s*([^\s]+)", line, re.I)
        if m:
            return m.group(2).strip().rstrip(" -->")
    return None


def extract_file_blocks(text: str) -> List[Dict[str, str]]:
    results: List[Dict[str, str]] = []
    for m in FENCE_RE.finditer(text or ""):
        info = (m.group("info") or "").strip()
        body = m.group("body") or ""
        path = _path_from_info(info) or _path_from_body(body)
        if path:
            results.append(
                {"path": path, "content": body, "lang": info.split()[0] if info else ""}
            )
    return results
