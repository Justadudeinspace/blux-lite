# -*- coding: utf-8 -*-
"""This module provides functions for loading and saving configuration data."""

import os
import yaml
from pathlib import Path
from typing import Dict, Any

ROOT = Path(__file__).resolve().parent.parent
CFG_DIR = ROOT / ".config" / "blux-lite-gold"
CFG_DIR.mkdir(parents=True, exist_ok=True)
CFG_PATH = CFG_DIR / "config.yaml"
ENV_PATH = CFG_DIR / ".env"


def load_config() -> Dict[str, Any]:
    """Load the configuration from the config.yaml file."""
    if CFG_PATH.exists():
        with CFG_PATH.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
    else:
        data = {}
    return data


def save_config(data: Dict[str, Any]):
    """Save the configuration to the config.yaml file."""
    with CFG_PATH.open("w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, sort_keys=False)


def load_env() -> Dict[str, str]:
    """Load the environment variables from the .env file."""
    env = {}
    if ENV_PATH.exists():
        for line in ENV_PATH.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip()
    return env


def save_env(env: Dict[str, str]):
    """Save the environment variables to the .env file."""
    lines = [f"{k}={v}" for k, v in env.items() if v is not None]
    ENV_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def apply_env():
    """Apply the environment variables from the .env file."""
    for k, v in load_env().items():
        os.environ.setdefault(k, v)


# default values guidance in code comments
