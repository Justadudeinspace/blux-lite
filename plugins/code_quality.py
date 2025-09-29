# -*- coding: utf-8 -*-
"""
BLUX Lite — Code Quality (Android/Kotlin)

Parse detekt (SARIF/HTML) and JaCoCo XML reports to summarize CI results.
"""
from __future__ import annotations
import json, xml.etree.ElementTree as ET
from pathlib import Path
import click


def _load_json(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def _summarize_jacoco(xml_path: Path):
    tree = ET.parse(xml_path)
    root = tree.getroot()
    counters = {}
    for c in root.iter("counter"):
        t = c.attrib.get("type")
        miss = int(c.attrib.get("missed", "0"))
        cov = int(c.attrib.get("covered", "0"))
        counters.setdefault(t, {"missed": 0, "covered": 0})
        counters[t]["missed"] += miss
        counters[t]["covered"] += cov
    summary = {
        k: {
            "missed": v["missed"],
            "covered": v["covered"],
            "coverage_pct": (
                (100.0 * v["covered"] / (v["covered"] + v["missed"]))
                if (v["covered"] + v["missed"]) > 0
                else 0.0
            ),
        }
        for k, v in counters.items()
    }
    return summary


def register(cli: click.Group) -> None:
    @cli.group(name="quality")
    def quality():
        """Summarize detekt & JaCoCo reports."""
        pass

    @quality.command("detekt-sarif")
    @click.argument("sarif_file")
    def detekt_sarif(sarif_file: str):
        try:
            data = _load_json(Path(sarif_file))
            runs = data.get("runs", [])
            total = 0
            by_rule = {}
            for r in runs:
                results = r.get("results", [])
                total += len(results)
                for it in results:
                    rule = it.get("ruleId", "unknown")
                    by_rule[rule] = by_rule.get(rule, 0) + 1
            click.echo(
                json.dumps({"total_issues": total, "by_rule": by_rule}, indent=2)
            )
        except FileNotFoundError:
            click.secho(f"Error: File not found at {sarif_file}", fg="red")
        except json.JSONDecodeError:
            click.secho(f"Error: Invalid JSON in {sarif_file}", fg="red")
        except Exception as e:
            click.secho(f"An unexpected error occurred: {e}", fg="red")

    @quality.command("jacoco")
    @click.argument("xml_report")
    def jacoco(xml_report: str):
        try:
            s = _summarize_jacoco(Path(xml_report))
            click.echo(json.dumps(s, indent=2))
        except FileNotFoundError:
            click.secho(f"Error: File not found at {xml_report}", fg="red")
        except ET.ParseError:
            click.secho(f"Error: Invalid XML in {xml_report}", fg="red")
        except Exception as e:
            click.secho(f"An unexpected error occurred: {e}", fg="red")
