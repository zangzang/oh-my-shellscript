import json
from pathlib import Path
from textual.app import App, ComposeResult
from textual.widgets import Tree, Static, Footer, Header, Button, Label, ListView, ListItem, RichLog, Input
from textual.containers import Horizontal, Vertical, Container
from textual.binding import Binding
from textual import events
from core.module import ModuleManager

# Reuse Logic from linux-setup/setup.py adapted for Windows structure

class SelectedList(ListView):
    BINDINGS = [
        Binding("space", "toggle_item", "Toggle", show=True),
        Binding("delete", "remove_item", "Remove", show=True),
    ]

    def __init__(self, manager: ModuleManager):
        super().__init__()
        self.manager = manager

    def refresh_list(self):
        self.clear()
        sorted_items = sorted(
            self.manager.context_items.items(),
            key=lambda x: x[0]
        )

        for item, is_selected in sorted_items:
            if is_selected:
                icon = "[green]✓[/]"
                label = f"{icon} {item}"
            else:
                icon = "[dim]✗[/]"
                label = f"{icon} [dim]{item}[/]"

            list_item = ListItem(Label(label))
            list_item.data = item
            self.append(list_item)

    def action_toggle_item(self):
        if self.highlighted_child:
            item_id = getattr(self.highlighted_child, 'data', None)
            if item_id:
                self.manager.toggle(item_id)
                self.refresh_list()
                try:
                    self.app.query_one(ModuleTree).refresh_all_labels()
                except:
                    pass

    def action_remove_item(self):
        if self.highlighted_child:
            item_id = getattr(self.highlighted_child, 'data', None)
            if item_id:
                self.manager.remove_from_context(item_id)
                self.refresh_list()
                try:
                    self.app.query_one(ModuleTree).refresh_all_labels()
                except:
                    pass

class InfoPanel(RichLog):
    def __init__(self, manager: ModuleManager):
        super().__init__(highlight=True, markup=True)
        self.manager = manager

    def update_info(self, mod_id: str = ""):
        self.clear()
        if mod_id:
            mod = self.manager.get_module(mod_id)
            if mod:
                self.write(f"[bold]{mod.name}[/]")
                if mod.description:
                    self.write(f"[dim]{mod.description}[/]")
                self.write(f"[dim]ID: {mod.id}[/]")
                self.write(f"[dim]Category: {mod.category}[/]")
                if mod.requires:
                    self.write("\n[yellow]Dependencies:[/]")
                    for dep in mod.requires:
                        self.write(f"  - {dep}")
                if mod.variants:
                    v_list = list(mod.variants.keys()) if isinstance(mod.variants, dict) else mod.variants
                    self.write(f"\n[cyan]Variants:[/ ] {', '.join(v_list)}")
                if mod.configuration:
                    self.write("\n[magenta]Configuration:[/]")
                    for key, value in mod.configuration.items():
                        self.write(f"  - [bold]{key}[/]: {value}")
        else:
            self.write("[dim]Select a module to see details")

class ModuleTree(Tree):
    BINDINGS = [
        Binding("space", "toggle_select", "Toggle", show=True),
    ]

    def __init__(self, manager: ModuleManager):
        super().__init__("Root")
        self.manager = manager
        self.node_map = {}
        self.show_root = False
        self.filter_text = ""

    def on_mount(self):
        self.rebuild_tree()

    def rebuild_tree(self, filter_text=""):
        self.filter_text = filter_text.lower()
        self.clear()
        self.node_map.clear()
        self.root.expand()
        
        self._build_presets()
        self._build_modules()

    def _build_presets(self):
        presets_node = self.root.add("📂 Presets", expand=True)
        
        if not self.manager.presets_dir.exists():
            return
            
        for preset_file in self.manager.presets_dir.glob("*.json"):
            try:
                name = preset_file.stem
                if self.filter_text and self.filter_text not in name.lower():
                    continue
                
                # Calculate if preset is active (all modules selected)
                is_active = False
                try:
                    data = json.loads(preset_file.read_text(encoding='utf-8'))
                    modules = data.get("modules", [])
                    if modules:
                        all_selected = True
                        for entry in modules:
                            # Derive key same as ModuleManager.load_preset
                            if isinstance(entry, str):
                                mod_id = entry
                                version = ""
                            else:
                                mod_id = entry.get("id")
                                version = entry.get("params", {}).get("version", "")
                            
                            key = f"{mod_id}:{version}" if version else mod_id
                            
                            # Check if this module is selected
                            if not self.manager.context_items.get(key):
                                all_selected = False
                                break
                        is_active = all_selected
                except:
                    pass

                mark = "[green]✓[/]" if is_active else "[dim]□[/]"
                label = f"{mark} {name}"
                node = presets_node.add_leaf(label)
                self.node_map[str(node._id)] = f"preset:{preset_file.name}"
            except:
                pass

    def _build_modules(self):
        modules_root = self.root.add("📦 Modules", expand=True)
        categories = self.manager.categories
        
        if not categories:
             # Fallback if no categories.json
             pass

        sorted_cats = sorted(categories.items(), key=lambda x: x[1].get("order", 999))
        
        for cat_key, cat_data in sorted_cats:
            cat_name = cat_data.get("name", cat_key)
            cat_match = self.filter_text in cat_name.lower()
            
            children = []
            
            # Subcategories
            if "subcategories" in cat_data:
                for sub_key, sub_data in cat_data["subcategories"].items():
                    sub_name = sub_data.get("name", sub_key)
                    sub_match = self.filter_text in sub_name.lower()
                    
                    mod_nodes = []
                    for mod_id in sub_data.get("modules", []):
                        if self._check_filter(mod_id, cat_match or sub_match):
                            mod_nodes.append(mod_id)
                            
                    if sub_match or mod_nodes:
                        children.append(("sub", sub_name, mod_nodes))
            
            # Modules
            if "modules" in cat_data:
                for mod_id in cat_data.get("modules", []):
                    if self._check_filter(mod_id, cat_match):
                        children.append(("mod", mod_id))
            
            if children or cat_match:
                cat_node = modules_root.add(cat_name, expand=True)
                for child in children:
                    if child[0] == "sub":
                        _, sub_name, mods = child
                        sub_node = cat_node.add(sub_name, expand=True)
                        for m in mods:
                            self._add_mod_node(sub_node, m)
                    else:
                        _, mod_id = child
                        self._add_mod_node(cat_node, mod_id)

    def _check_filter(self, mod_id, force_include):
        mod = self.manager.get_module(mod_id)
        if not mod: return False
        if force_include: return True
        return (self.filter_text in mod.name.lower()) or (self.filter_text in mod.id.lower())

    def _add_mod_node(self, parent, mod_id):
        mod = self.manager.get_module(mod_id)
        if not mod: return
        
        if mod.variants:
            mod_node = parent.add(f"📦 {mod.name}", expand=bool(self.filter_text))
            variants = list(mod.variants.keys()) if isinstance(mod.variants, dict) else mod.variants
            for v in variants:
                key = f"{mod.id}:{v}"
                label = self._get_label(key, v)
                node = mod_node.add_leaf(label)
                self.node_map[str(node._id)] = key
        else:
            label = self._get_label(mod_id, mod.name)
            node = parent.add_leaf(label)
            self.node_map[str(node._id)] = mod_id

    def _get_label(self, key, name):
        selected = self.manager.context_items.get(key)
        if selected is None:
            selected = key in self.manager.selected
        
        mark = "[green]✓[/]" if selected else "[dim]□[/]"
        # If explicitly set to False in context (removed), show different?
        # For now simple check
        return f"{mark} {name}"

    def refresh_all_labels(self):
        # Textual Tree doesn't easily support updating all labels without walking
        # Rebuilding might be easier or just walk visible
        # For performance, we can just rebuild or smart update. 
        # Rebuild is safest for now.
        self.rebuild_tree(self.filter_text)

    def action_toggle_select(self):
        node = self.cursor_node
        if node and str(node._id) in self.node_map:
            item_id = self.node_map[str(node._id)]
            
            if item_id.startswith("preset:"):
                # node.label returns a Text object, str(node.label) returns plain text without markup
                current_text = str(node.label)
                is_checked = "✓" in current_text
                
                preset_name = item_id.split(":", 1)[1]
                # We use the stem (filename without extension) for display usually, 
                # but let's just use the name from the label to be safe or re-derive it.
                display_name = preset_name.replace(".json", "")
                
                preset_path = self.manager.presets_dir / preset_name
                
                if is_checked:
                    # Unload (Uncheck)
                    self.manager.unload_preset(preset_path)
                    # Re-apply full markup
                    node.set_label(f"[dim]□[/] {display_name}")
                    self.app.notify(f"Unloaded preset: {display_name}")
                else:
                    # Load (Check)
                    self.manager.load_preset(preset_path, clear_selection=False)
                    # Re-apply full markup
                    node.set_label(f"[green]✓[/] {display_name}")
                    self.app.notify(f"Loaded preset: {display_name}")
                
                self.refresh_all_labels()
                self.app.query_one(SelectedList).refresh_list()
                return

            self.manager.toggle(item_id)
            self.refresh_all_labels()
            self.app.query_one(SelectedList).refresh_list()

    def on_tree_node_highlighted(self, event):
        if str(event.node._id) in self.node_map:
            item_id = self.node_map[str(event.node._id)]
            if not item_id.startswith("preset:"):
                self.app.query_one(InfoPanel).update_info(item_id)

class SetupApp(App):
    CSS = """
    Screen {
        layout: vertical;
    }
    Header {
        dock: top;
        height: 1;
        background: $primary;
        color: white;
    }
    Footer {
        dock: bottom;
        height: 1;
    }
    #main-container {
        layout: horizontal;
        height: 1fr;
    }
    #left-pane {
        width: 40%;
        height: 100%;
        border-right: solid $primary;
    }
    #right-pane {
        width: 60%;
        layout: vertical;
    }
    #search-box {
        dock: top;
        height: 3;
        margin: 0 0 1 0;
    }
    #info-box {
        height: 40%;
        border-top: solid $primary;
    }
    """

    BINDINGS = [
        ("q", "quit", "Quit"),
        ("i", "install", "Install"),
        ("d", "dry_run", "Dry Run"),
        ("/", "focus_search", "Search"),
    ]

    def __init__(self, manager):
        super().__init__()
        self.manager = manager

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        
        with Container(id="main-container"):
            with Vertical(id="left-pane"):
                yield Input(placeholder="Search modules...", id="search-box")
                yield ModuleTree(self.manager)
            
            with Vertical(id="right-pane"):
                yield Label("[bold]Selected Modules[/]")
                yield SelectedList(self.manager)
                with Vertical(id="info-box"):
                    yield Label("[bold]Info[/]")
                    yield InfoPanel(self.manager)
        
        yield Footer()

    def on_input_changed(self, event: Input.Changed):
        if event.input.id == "search-box":
            self.query_one(ModuleTree).rebuild_tree(event.value)

    def action_focus_search(self):
        self.query_one("#search-box").focus()

    def action_install(self):
        if not self.manager.selected:
            self.notify("No modules selected!", severity="warning")
            return
        self.exit(result=("execute", self.manager.resolve_dependencies()))

    def action_dry_run(self):
        if not self.manager.selected:
            self.notify("No modules selected!", severity="warning")
            return
        self.exit(result=("dry-run", self.manager.resolve_dependencies()))

