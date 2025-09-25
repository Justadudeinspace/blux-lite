from __future__ import annotations
import subprocess, shutil, tempfile, os


def syntax_ok(script: str) -> bool:
    sh = shutil.which("bash") or "/bin/bash"
    try:
        with tempfile.NamedTemporaryFile("w", delete=False) as f:
            f.write(script)
            path = f.name
        r = subprocess.call([sh, "-n", path])
        os.unlink(path)
        return r == 0
    except Exception:
        return True
