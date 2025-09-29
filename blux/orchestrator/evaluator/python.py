from __future__ import annotations


def syntax_ok(code: str) -> bool:
    try:
        compile(code, "<string>", "exec")
        return True
    except Exception:
        return False
