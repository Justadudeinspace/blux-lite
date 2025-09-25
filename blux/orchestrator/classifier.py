# -*- coding: utf-8 -*-

from dataclasses import dataclass
from typing import Set

SKILL_KEYWORDS = {
    "tests": {"test", "pytest", "unit test", "assert"},
    "python": {"python", "py", "pip", "venv"},
    "refactor": {"refactor", "rewrite"},
    "analysis": {"analyze", "analysis", "explain", "reason"},
    "vision": {"image", "screenshot", "ocr"},
    "web": {"web", "http", "api", "request"},
    "code": {"code", "function", "class", "module", "script"},
}

DATASET_KEYWORDS = {
    "coding": {"code", "function", "tests", "bug", "fix"},
    "general": {"explain", "analyze", "summary"},
    "reasoning": {"reason", "logic", "why", "prove"},
    "advanced-reasoning": {"formal", "proof", "optimize", "design"},
    "tools": {"pytest", "unittest", "cli", "bash", "shell"},
}


@dataclass
class TaskProfile:
    lang: str
    skills: Set[str]
    datasets: Set[str]


def classify(task: str) -> TaskProfile:
    t = task.lower()
    skills = set()
    datasets = set()
    for s, kws in SKILL_KEYWORDS.items():
        if any(k in t for k in kws):
            skills.add(s)
    for d, kws in DATASET_KEYWORDS.items():
        if any(k in t for k in kws):
            datasets.add(d)
    lang = "python"
    if "bash" in t or "shell" in t:
        lang = "python"  # still producing python for now
    # always include generic tags when none
    if not skills:
        skills.add("code")
    if not datasets:
        datasets.add("coding")
    return TaskProfile(lang=lang, skills=skills, datasets=datasets)
