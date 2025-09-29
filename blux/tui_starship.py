# blux/tui_starship.py — stable minimal “starship” TUI
from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical, Grid, Container
from textual.widgets import Header, Footer, Static, ListItem, ListView
from textual.reactive import reactive
from textual import events

CSS_PATH = "blux/tui_starship.tcss"

PLUGINS = [
    {"name": "Genkit", "ver": "0.5.1", "on": True,  "desc": "AI framework integration"},
    {"name": "Code Quality", "ver": "1.2.0", "on": True,  "desc": "Linting & formatting"},
    {"name": "Heimdall Tools", "ver": "0.8.3", "on": False, "desc": "Samsung download-mode ops"},
    {"name": "Payload Tools", "ver": "0.9.0", "on": True,  "desc": "Payload builders (update avail)"},
    {"name": "APK Retool", "ver": "1.0.5", "on": False, "desc": "Decompilation & analysis"},
]

class Banner(Static):
    def on_mount(self) -> None:
        self.update("[b][cyan]BLUX Lite GOLD[/] — [magenta]Starship Ops Console[/][/b]")
        self.add_class("glowing-text")

class StatusPanel(Static):
    def on_mount(self) -> None:
        self.update(
            "[dim]SYSTEM STATUS[/dim]\n"
            "CPU: [green]|||||    [/]\n"
            "MEM: [yellow]||||||||  [/]\n"
            "NET: [green]UP[/]   DISK: [cyan]||||[/]"
        )
        self.add_class("holo-card")

class ActivityLog(Static):
    def on_mount(self) -> None:
        self.update(
            "[dim]ACTIVITY LOG[/dim]\n"
            "• Router: TUI mode engaged\n"
            "• Plugins: 3 enabled / 2 disabled\n"
            "• Tip: Press [b]F2[/b] to open Plugin Bay"
        )
        self.add_class("holo-card")

class PluginBay(Container):
    selection = reactive(0)
    def compose(self) -> ComposeResult:
        items = []
        for p in PLUGINS:
            dot = "●" if p["on"] else "○"
            color = "green" if p["on"] else "red"
            line = f"[b {color}]{dot}[/] [cyan]{p['name']}[/] [dim]v{p['ver']}[/] — {p['desc']}"
            items.append(ListItem(Static(line)))
        self.list_view = ListView(*items, id="plugin-list")
        self.info = Static("[b]Plugin Bay[/b]\n[dim]Select a plugin for details[/]", id="plugin-info", classes="holo-card")
        self.hints = Static("[green]⏵ Enable[/]   [blue]Install[/]   [magenta]Configure[/]", id="plugin-hints")
        yield Vertical(
            Horizontal(self.list_view, self.info),
            self.hints,
            id="plugin-bay-wrap"
        )

    def on_mount(self) -> None:
        self._update_info(0)

    def _update_info(self, idx: int) -> None:
        p = PLUGINS[idx]
        txt = f"[b]{p['name']}[/b]\n[dim]{p['desc']}[/]\n\n[green]⏵ Enable[/]   [blue]Install[/]   [magenta]Configure[/]"
        self.info.update(txt)

    def on_list_view_highlighted(self, event: ListView.Highlighted) -> None:
        self.selection = event.index
        self._update_info(self.selection)

class Starship(App):
    mode = reactive("Cockpit")
    BINDINGS = [
        ("f1", "help", "Help"),
        ("f2", "show_plugins", "Plugins"),
        ("f3", "notify_system", "System"),
        ("f4", "notify_files", "Files"),
        ("g", "layout_grid", "Grid"),
        ("c", "layout_cockpit", "Cockpit"),
        ("q", "quit", "Quit"),
    ]

    def compose(self) -> ComposeResult:
        # Build initial layout directly; no .mount() calls here
        yield Header()
        yield Banner()
        # Tiny mode label under header
        yield Static("Mode: [b][cyan]Cockpit[/][/b]   (F1 Help)", id="mode-label")
        # Initial COCKPIT inlined so Container is mounted when the app starts
        yield Container(
            Horizontal(
                Vertical(StatusPanel(), classes="side"),
                ActivityLog(),
                Vertical(StatusPanel(), classes="side"),
                classes="cockpit",
            ),
            id="body",
        )
        yield Footer()

    def on_mount(self) -> None:
        # Store handle to the mounted body container for future swaps
        self.body: Container = self.query_one("#body", Container)
        self.mode_label: Static = self.query_one("#mode-label", Static)

    # Layout swaps after mount are safe
    def _render_grid(self) -> None:
        self.body.remove_children()
        self.body.mount(
            Grid(
                Static("Plugins", classes="holo-card center"),
                Static("System Monitor", classes="holo-card center"),
                Static("File Browser", classes="holo-card center"),
                Static("Context", classes="holo-card center"),
                classes="grid",
            )
        )

    def _render_cockpit(self) -> None:
        self.body.remove_children()
        self.body.mount(
            Horizontal(
                Vertical(StatusPanel(), classes="side"),
                ActivityLog(),
                Vertical(StatusPanel(), classes="side"),
                classes="cockpit",
            )
        )

    # Actions
    def action_layout_grid(self) -> None:
        self.mode = "Grid"
        self.mode_label.update("Mode: [b][cyan]Grid[/][/b]   (F1 Help)")
        self._render_grid()

    def action_layout_cockpit(self) -> None:
        self.mode = "Cockpit"
        self.mode_label.update("Mode: [b][cyan]Cockpit[/][/b]   (F1 Help)")
        self._render_cockpit()
    def action_show_plugins(self) -> None:
        self.body.remove_children()
        self.body.mount(PluginBay())
    def action_notify_system(self) -> None: self.notify("System panel TBD", timeout=2)
    def action_notify_files(self) -> None: self.notify("File browser TBD", timeout=2)
    def action_help(self) -> None:
        self.notify("Keys: F1 Help • F2 Plugins • F3 System • F4 Files • g Grid • c Cockpit • q Quit", timeout=4)

if __name__ == "__main__":
    Starship().run()
