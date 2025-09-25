# -*- coding: utf-8 -*-
"""BLUX Lite Gold — .libf Plugin Loader (repo-local)
Loads plugins from ./plugins/liberation_framework/*.py
"""
import sys, importlib.util, logging
from pathlib import Path

LOG = logging.getLogger("blux.libf_loader")
if not LOG.handlers:
    LOG.addHandler(logging.StreamHandler())
    LOG.setLevel(logging.INFO)


def _iter_plugin_files(root: Path):
    if not root.exists():
        LOG.warning("No plugin dir: %s", root)
        return []
    return [p for p in root.rglob("*.py") if p.name != "__init__.py"]


def _import_from_path(path: Path):
    spec = importlib.util.spec_from_file_location(f"blux_plugin_{path.stem}", str(path))
    if not spec or not spec.loader:
        raise ImportError(f"Cannot load {path}")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)  # type: ignore
    return mod


def load_libf_plugins(cli):
    root = Path.cwd() / "plugins" / "liberation_framework"
    loaded = []
    for f in _iter_plugin_files(root):
        try:
            mod = _import_from_path(f)
            if hasattr(mod, "register"):
                mod.register(cli)
                LOG.info("Loaded plugin: %s", f.name)
                loaded.append(f)
            else:
                LOG.error("Missing register(cli): %s", f)
        except Exception as e:
            LOG.exception("Failed loading %s: %s", f, e)
    return loaded
