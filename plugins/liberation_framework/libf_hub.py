# -*- coding: utf-8 -*-
"""BLUX .libf Hub — central controller for .libf plugins
- Reads groups/keys from ./.config/blux-lite/router.yaml (if present)
- Persists libf menus/keys/route json in ./.config/libf/tui.json (and router.json)
"""
import sys, json, subprocess
from pathlib import Path
import click

from blux.settings import SETTINGS

ROUTER_YAML = Path(SETTINGS["config_dir"]) / "router.yaml"
LIBF_CFG_DIR = Path(SETTINGS["libf_config_dir"])
LIBF_CFG_DIR.mkdir(parents=True, exist_ok=True)
TUI_JSON = LIBF_CFG_DIR / "tui.json"
ROUTER_JSON = LIBF_CFG_DIR / "router.json"

DEFAULT_GROUPS = {
    "Notes": ["libf-note"],
    "Sessions": ["libf-save", "project sessions"],
    "Projects": [
        "project show",
        "project set",
        "libf init",
        "libf templates",
        "libf import",
        "libf install-framework",
    ],
    "Export": ["libf-export"],
}
DEFAULT_KEYS = {
    "libf-note": ["n"],
    "libf-save": ["s"],
    "libf-export": ["e"],
    "project show": ["P"],
    "project set": [],
    "project sessions": ["J"],
    "libf init": [],
    "libf templates": [],
    "libf import": [],
    "libf install-framework": [],
}


def _load_yaml(path: Path):
    if not path.exists():
        return {}
    try:
        import yaml  # type: ignore

        return yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    except Exception:
        # basic fallback
        return {}


def _router_from_yaml():
    d = _load_yaml(ROUTER_YAML)
    libf = (d or {}).get("libf", {})
    groups = libf.get("groups") or DEFAULT_GROUPS
    keys = libf.get("keys") or DEFAULT_KEYS
    return groups, keys


def _load_tui_json():
    if TUI_JSON.exists():
        try:
            return json.loads(TUI_JSON.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {"keys": DEFAULT_KEYS.copy()}


def _save_tui_json(cfg):
    TUI_JSON.write_text(json.dumps(cfg, ensure_ascii=False, indent=2), encoding="utf-8")


def _command_signature(cmd):
    params = []
    for p in cmd.params:
        kind = "arg" if isinstance(p, click.Argument) else "option"
        params.append(
            {
                "name": p.name,
                "param_decls": list(getattr(p, "opts", []))
                + list(getattr(p, "secondary_opts", [])),
                "kind": kind,
                "required": getattr(p, "required", False),
                "nargs": getattr(p, "nargs", 1),
            }
        )
    return params


def _collect_commands(cli):
    out = {}
    for name, cmd in cli.commands.items():
        out[name] = cmd
        if isinstance(cmd, click.Group):
            for subn, subc in cmd.commands.items():
                out[f"{name} {subn}"] = subc
    return out


def _categorize(names, groups_cfg):
    used, groups_out = set(), []
    for gname, items in groups_cfg.items():
        rows = [n for n in names if n in items]
        if rows:
            groups_out.append({"name": gname, "items": rows})
            used.update(rows)
    rest = [n for n in names if n not in used]
    if rest:
        groups_out.append({"name": "Other", "items": rest})
    return groups_out


def _is_libf_related(name):
    return name.startswith("libf") or name.startswith("project")


def register(cli):
    @cli.group(name="libf-hub")
    def hub():
        """Central controller for .libf plugins."""
        pass

    @hub.command("discover")
    def discover():
        cmds = _collect_commands(cli)
        names = [n for n in cmds.keys() if _is_libf_related(n)]
        for n in sorted(names):
            click.echo(n)

    @hub.command("menu")
    @click.option(
        "--out",
        default="",
        help="Write menu JSON to file. Default: ./.config/libf/router.json",
    )
    @click.option("--project", default="", help="Current project name to include")
    def menu(out, project):
        groups_yaml, keys_yaml = _router_from_yaml()
        tui_cfg = _load_tui_json()
        keys = tui_cfg.get("keys", {})
        # keys from yaml serve as defaults; tui.json overrides
        for k, v in (keys_yaml or {}).items():
            keys.setdefault(k, v)

        cmds = _collect_commands(cli)
        names = [n for n in cmds.keys() if _is_libf_related(n)]
        entries = []
        for n in sorted(names):
            cmd = cmds[n]
            entries.append(
                {
                    "name": n,
                    "help": (cmd.help or "").strip(),
                    "params": _command_signature(cmd),
                    "keys": keys.get(n, []),
                }
            )
        data = {
            "title": "BLUX .libf Hub",
            "project": project or "default",
            "commands": entries,
            "groups": _categorize(
                [e["name"] for e in entries], groups_yaml or DEFAULT_GROUPS
            ),
        }
        s = json.dumps(data, ensure_ascii=False, indent=2)
        dest = Path(out) if out else (LIBF_CFG_DIR / "router.json")
        dest.write_text(s, encoding="utf-8")
        click.echo(str(dest))

    @hub.group("keys")
    def keys():
        """Manage keybindings used by the TUI (stored in ./.config/libf/tui.json)."""
        pass

    @keys.command("list")
    def keys_list():
        cfg = _load_tui_json()
        for k, v in sorted(cfg.get("keys", {}).items()):
            click.echo(f"{k:24} -> {', '.join(v) if v else '(none)'}")

    @keys.command("set")
    @click.argument("command", nargs=-1, required=True)
    @click.argument("binding", required=True)
    def keys_set(command, binding):
        name = " ".join(command)
        cfg = _load_tui_json()
        vals = set(cfg.setdefault("keys", {}).get(name, []))
        vals.add(binding)
        cfg["keys"][name] = sorted(vals)
        _save_tui_json(cfg)
        click.echo(f"Set key '{binding}' for '{name}'")

    @keys.command("unset")
    @click.argument("command", nargs=-1, required=True)
    @click.argument("binding", required=True)
    def keys_unset(command, binding):
        name = " ".join(command)
        cfg = _load_tui_json()
        vals = set(cfg.setdefault("keys", {}).get(name, []))
        if binding in vals:
            vals.remove(binding)
            cfg["keys"][name] = sorted(vals)
            _save_tui_json(cfg)
            click.echo(f"Removed key '{binding}' from '{name}'")
        else:
            click.echo("No change.")

    @hub.command("tui-paths")
    def tui_paths():
        click.echo(f"TUI JSON : {TUI_JSON}")
        click.echo(f"Router   : {ROUTER_JSON}")
        click.echo(f"Router Y : {ROUTER_YAML}")
