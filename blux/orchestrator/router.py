from __future__ import annotations
from typing import Optional, Dict, Any
from .registry import engines_available, pick_engine_for_model


def route(model: Dict[str, Any]) -> Optional[str]:
    av = engines_available()
    return pick_engine_for_model(model, av)
