# -*- coding: utf-8 -*-
"""This module provides functions for detecting the user's intent based on the prompt."""
import re, os
from pathlib import Path
from typing import Set

try:
    import yaml
except Exception:
    yaml = None  # type: ignore
from .utils import sanitize_prompt
from .settings import CONF_DIR

from .keywords import CODING_KEYWORDS, GENERAL_KEYWORDS

ROUTER_YAML = Path(os.getenv("BLUX_ROUTER_YAML", str(CONF_DIR / "router.yaml")))


def detect_intent(prompt: str) -> str:
    """Detect the user's intent based on the prompt.

    The intent is determined by a set of rules, which are defined in the
    `router.yaml` file and in the `CODING_KEYWORDS` and `GENERAL_KEYWORDS`
    sets.

    Args:
        prompt: The user's prompt.

    Returns:
        The detected intent, which can be either "coding" or "general".
    """
    p = prompt.lower()
    if yaml and ROUTER_YAML.exists():
        try:
            rules = yaml.safe_load(ROUTER_YAML.read_text(encoding="utf-8")) or {}
            # 1) Keyword lists schema
            coding_rules = [
                str(x).lower() for x in (rules.get("coding_keywords", []) or [])
            ]
            general_rules = [
                str(x).lower() for x in (rules.get("general_keywords", []) or [])
            ]
            if coding_rules and any(kw in p for kw in coding_rules):
                return "coding"
            if general_rules and any(kw in p for kw in general_rules):
                return "general"
            # 2) Routes schema (either top-level list or mapping with 'routes')
            route_list = None
            if isinstance(rules, list):
                route_list = rules
            elif isinstance(rules, dict):
                route_list = rules.get("routes")
            if isinstance(route_list, list):
                for r in route_list:
                    try:
                        pat = str(r.get("match", ".*"))
                        if re.search(pat, p, flags=re.IGNORECASE):
                            # Explicit coding_mode wins
                            if isinstance(r.get("coding_mode"), bool):
                                return "coding" if r.get("coding_mode") else "general"
                            # Otherwise, infer coding by engine/model keywords
                            eng = str(r.get("engine", ""))
                            if any(k in eng.lower() for k in ("coder", "code")):
                                return "coding"
                            # If we matched a route but can't infer, fall through to keywords
                    except Exception:
                        pass
        except Exception:
            pass
    # Default to keyword-based detection if the router.yaml file is not present
    # or if no rules match.
    if any(kw in p for kw in CODING_KEYWORDS):
        return "coding"
    return "general"
