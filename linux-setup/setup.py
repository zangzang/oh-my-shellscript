#!/usr/bin/env python3
"""
Linux Setup Assistant v4.0 - Python TUI (textual)
Fast and intuitive module selection interface
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional

# Check for textual installation
try:
    from textual.app import App, ComposeResult
    from textual.widgets import Tree, Static, Footer, Header, Button, Label, ListView, ListItem, RichLog
    from textual.containers import Horizontal, Vertical, Container
    from textual.binding import Binding
    from textual import events
except ImportError:
    print("Library 'textual' is required. Installing...")
    subprocess.run([sys.executable, "-m", "pip", "install", "textual", "-q"])
    from textual.app import App, ComposeResult
    from textual.widgets import Tree, Static, Footer, Header, Button, Label, ListView, ListItem, RichLog
    from textual.containers import Horizontal, Vertical, Container
    from textual.binding import Binding
    from textual import events


SCRIPT_DIR = Path(__file__).parent.resolve()
MODULES_DIR = SCRIPT_DIR / "modules"
PRESETS_DIR = SCRIPT_DIR / "presets"
CONFIG_DIR = SCRIPT_DIR / "config"


class ModuleInfo:
    """Module information class"""
    def __init__(self, path: Path):
        self.path = path
        self.meta_file = path / "meta.json"
        self._meta = None
    
    @property
    def meta(self) -> dict:
        if self._meta is None:
            if self.meta_file.exists():
                self._meta = json.loads(self.meta_file.read_text())
            else:
                self._meta = {}
        return self._meta
    
    @property
    def id(self) -> str:
        return self.meta.get("id", "")
    
    @property
    def name(self) -> str:
        return self.meta.get("name", self.path.name)
    
    @property
    def description(self) -> str:
        return self.meta.get("description", "")
    
    @property
    def requires(self) -> list:
        return self.meta.get("requires", [])
    
    @property
    def variants(self) -> list:
        return self.meta.get("variants", [])


class ModuleManager:
    """Module manager class"""
    def __init__(self):
        self.modules: dict[str, ModuleInfo] = {}
        self.categories: dict = {}
        self.selected: set[str] = set()
        self._load_modules()
        self._load_categories()
    
    def _load_modules(self):
        """Load all modules from directory"""
        for meta_file in MODULES_DIR.rglob("meta.json"):
            mod = ModuleInfo(meta_file.parent)
            if mod.id:
                self.modules[mod.id] = mod
                # Also allow access by folder name
                self.modules[meta_file.parent.name] = mod
    
    def _load_categories(self):
        """Load category configurations"""
        cat_file = CONFIG_DIR / "categories.json"
        if cat_file.exists():
            self.categories = json.loads(cat_file.read_text())
    
    def get_module(self, mod_id: str) -> Optional[ModuleInfo]:
        """Find module by ID or folder name"""
        # Direct match
        if mod_id in self.modules:
            return self.modules[mod_id]
        # Split variant (e.g., dev.java:17 -> dev.java)
        base_id = mod_id.split(":")[0]
        return self.modules.get(base_id)
    
    def toggle(self, item_id: str):
        """Toggle selection of a module"""
        if item_id in self.selected:
            self.selected.discard(item_id)
        else:
            self.selected.add(item_id)
    
    def resolve_dependencies(self) -> list[str]:
        """Resolve dependencies and return installation order"""
        result = []
        visited = set()
        
        def resolve(item_id: str):
            if item_id in visited:
                return
            visited.add(item_id)
            
            mod = self.get_module(item_id)
            if mod:
                for dep in mod.requires:
                    resolve(dep)
            
            result.append(item_id)
        
        for item in sorted(self.selected):
            resolve(item)
        
        return result
    
    def load_preset(self, preset_file: Path, clear_selection: bool = True):
        """Load modules from a preset file"""
        if clear_selection:
            self.selected.clear()
        
        if preset_file.exists():
            data = json.loads(preset_file.read_text())
            for entry in data.get("modules", []):
                mod_id = entry.get("id", "")
                version = entry.get("params", {}).get("version", "")
                selected = entry.get("params", {}).get("selected", True)
                
                if selected:
                    key = f"{mod_id}:{version}" if version else mod_id
                    self.selected.add(key)

    def unload_preset(self, preset_file: Path):
        """Remove modules of a preset from selection"""
        if preset_file.exists():
            data = json.loads(preset_file.read_text())
            for entry in data.get("modules", []):
                mod_id = entry.get("id", "")
                version = entry.get("params", {}).get("version", "")
                
                key = f"{mod_id}:{version}" if version else mod_id
                self.selected.discard(key)


class SelectedList(ListView):
    """List of selected items (supports removal)"""
    
    BINDINGS = [
        Binding("space", "remove_item", "Remove", show=True),
        Binding("delete", "remove_item", "Remove", show=False),
        Binding("backspace", "remove_item", "Remove", show=False),
    ]
    
    def __init__(self, manager: ModuleManager):
        super().__init__()
        self.manager = manager
    
    def refresh_list(self):
        """Refresh the displayed list of selected items"""
        self.clear()
        for item in sorted(self.manager.selected):
            list_item = ListItem(Label(f"[green]✓[/] {item}"))
            list_item.data = item  # Store data for retrieval
            self.append(list_item)
    
    def action_remove_item(self):
        """Remove the highlighted item from selection"""
        if self.highlighted_child:
            item_id = getattr(self.highlighted_child, 'data', None)
            if item_id:
                self.manager.selected.discard(item_id)
                self.refresh_list()
                # Also update the tree view
                try:
                    tree = self.app.query_one(ModuleTree)
                    tree.refresh_all_labels()
                except Exception:
                    pass


class InfoPanel(RichLog):
    """Panel for displaying module information"""
    
    def __init__(self, manager: ModuleManager):
        super().__init__(highlight=True, markup=True)
        self.manager = manager
        self.current_id = ""
        self.can_focus = True
    
    def set_content(self, content: str):
        """Set information content directly"""
        self.clear()
        self.write(content)
    
    def update_info(self, mod_id: str = ""):
        """Update information based on module ID"""
        self.current_id = mod_id
        self.clear()
        
        if mod_id:
            mod = self.manager.get_module(mod_id)
            if mod:
                self.write(f"[bold]{mod.name}[/]")
                if mod.description:
                    self.write(f"[dim]{mod.description}[/]")
                
                self.write(f"[dim]ID: {mod.id}[/]")
                
                if mod.requires:
                    self.write("")
                    self.write("[yellow]Dependencies:[/]")
                    for dep in mod.requires:
                        self.write(f"  ↳ {dep}")
                if mod.variants:
                    self.write("")
                    self.write(f"[cyan]Variants:[/]")
        else:
            self.write("[dim]Select a module to see details")


class ModuleTree(Tree):
    """Tree widget for displaying presets and modules"""
    
    BINDINGS = [
        Binding("space", "toggle_select", "Toggle", show=True),
    ]
    
    def __init__(self, manager: ModuleManager):
        super().__init__("Root")
        self.manager = manager
        self.node_map: dict[str, str] = {}  # node_id -> module_id
        self.show_root = False
    
    def on_mount(self):
        """Build the tree structure on mount"""
        self.root.expand()
        self._build_presets()
        self._build_tree()
    
    def _build_presets(self):
        """Build the presets section grouped by category"""
        presets_node = self.root.add("📂 Presets", expand=True)
        
        # 1. Load and group all presets
        preset_groups = {}  # category -> list of (name, file_name)
        
        for preset_file in PRESETS_DIR.glob("*.json"):
            try:
                data = json.loads(preset_file.read_text(encoding='utf-8'))
                name = data.get("name", preset_file.stem)
                category = data.get("category", "General")
                
                if category not in preset_groups:
                    preset_groups[category] = []
                preset_groups[category].append((name, preset_file.name))
            except Exception:
                pass
        
        # 2. Build tree nodes sorted by category name
        for category in sorted(preset_groups.keys()):
            cat_node = presets_node.add(f"📁 {category}", expand=True)
            
            # Sort items within group by name
            items = sorted(preset_groups[category], key=lambda x: x[0])
            
            for name, filename in items:
                node = cat_node.add_leaf(f"☐ {name}")
                self.node_map[str(node._id)] = f"preset:{filename}"

    def _build_tree(self):
        """Build the module tree based on category configuration"""
        modules_root = self.root.add("📦 Modules", expand=True)
        
        categories = self.manager.categories
        
        # Sort categories by defined order
        sorted_cats = sorted(
            categories.items(),
            key=lambda x: x[1].get("order", 99)
        )
        
        for cat_key, cat_data in sorted_cats:
            cat_name = cat_data.get("name", cat_key)
            cat_node = modules_root.add(cat_name, expand=True)
            
            # Subcategories
            if "subcategories" in cat_data:
                for sub_key, sub_data in cat_data["subcategories"].items():
                    sub_name = sub_data.get("name", sub_key)
                    sub_node = cat_node.add(sub_name, expand=True)
                    
                    for mod_folder in sub_data.get("modules", []):
                        self._add_module_nodes(sub_node, mod_folder)
            
            # Direct modules
            for mod_folder in cat_data.get("modules", []):
                self._add_module_nodes(cat_node, mod_folder)
    
    def _add_module_nodes(self, parent_node, mod_folder: str):
        """Add module nodes to a parent category node"""
        mod = self.manager.modules.get(mod_folder)
        if not mod:
            return
        
        if mod.variants:
            # Group variants in a sub-tree
            mod_node = parent_node.add(f"📦 {mod.name}", expand=False)
            for v in mod.variants:
                key = f"{mod.id}:{v}"
                mark = "☑" if key in self.manager.selected else "☐"
                label = f"{mark} {v}"
                node = mod_node.add_leaf(label)
                self.node_map[str(node._id)] = key
        else:
            key = mod.id
            mark = "☑" if key in self.manager.selected else "☐"
            label = f"{mark} {mod.name}"
            node = parent_node.add_leaf(label)
            self.node_map[str(node._id)] = key

    def action_toggle_select(self):
        """Handle toggle selection on space key"""
        node = self.cursor_node
        if node and str(node._id) in self.node_map:
            item_id = self.node_map[str(node._id)]
            
            # Handle preset selection
            if item_id.startswith("preset:"):
                current_label = str(node.label)
                is_checked = "☑" in current_label
                
                preset_file = PRESETS_DIR / item_id.split(":", 1)[1]
                
                if is_checked:
                    # Uncheck -> Remove modules
                    new_label = current_label.replace("☑ ", "☐ ")
                    node.set_label(new_label)
                    self.manager.unload_preset(preset_file)
                    self.app.notify(f"Unloaded preset: {preset_file.stem}")
                else:
                    # Check -> Add modules (keep existing)
                    new_label = current_label.replace("☐ ", "☑ ")
                    node.set_label(new_label)
                    self.manager.load_preset(preset_file, clear_selection=False)
                    self.app.notify(f"Loaded preset: {preset_file.stem}")

                self.refresh_all_labels()
                try:
                    selected_list = self.app.query_one(SelectedList)
                    selected_list.refresh_list()
                except Exception:
                    pass
                return

            # Handle standard module selection
            self.manager.toggle(item_id)
            self._update_node_label(node, item_id)
            # Update selected list view
            try:
                selected_list = self.app.query_one(SelectedList)
                selected_list.refresh_list()
            except Exception:
                pass
    
    def _update_node_label(self, node, mod_id: str):
        """Update node label with checkbox mark"""
        if mod_id.startswith("preset:"):
            return

        mod = self.manager.get_module(mod_id)
        if mod:
            mark = "☑" if mod_id in self.manager.selected else "☐"
            if ":" in mod_id:
                version = mod_id.split(":")[1]
                # Show only version for variant modules
                node.set_label(f"{mark} {version}")
            else:
                node.set_label(f"{mark} {mod.name}")
    
    def on_tree_node_selected(self, event: Tree.NodeSelected):
        """Display info when node is selected"""
        self._show_node_info(event.node)
    
    def on_tree_node_highlighted(self, event: Tree.NodeHighlighted):
        """Display info when node is highlighted (cursor moves)"""
        self._show_node_info(event.node)
    
    def _show_node_info(self, node):
        """Show information about the node in info panel"""
        if str(node._id) in self.node_map:
            item_id = self.node_map[str(node._id)]
            
            # Show preset information
            if item_id.startswith("preset:"):
                preset_file = PRESETS_DIR / item_id.split(":", 1)[1]
                try:
                    data = json.loads(preset_file.read_text())
                    desc = data.get("description", "")
                    modules = data.get("modules", [])
                    
                    lines = [f"[bold]📄 {data.get('name', preset_file.stem)}[/]"]
                    if desc:
                        lines.append(f"[dim]{desc}[/]")
                    lines.append("")
                    lines.append(f"[yellow]Included Modules ({len(modules)}):[/]")
                    for m in modules:
                        mid = m.get("id", "")
                        ver = m.get("params", {}).get("version", "")
                        if ver:
                            lines.append(f"  - {mid} ({ver})")
                        else:
                            lines.append(f"  - {mid}")
                    
                    try:
                        info = self.app.query_one(InfoPanel)
                        info.set_content("\n".join(lines))
                    except Exception:
                        pass
                except Exception:
                    pass
                return

            # Show standard module information
            try:
                info = self.app.query_one(InfoPanel)
                info.update_info(item_id)
            except Exception:
                pass
    
    def refresh_all_labels(self):
        """Refresh labels for all nodes in the tree"""
        for node_id, mod_id in self.node_map.items():
            for node in self.root.children:
                self._refresh_node_recursive(node, mod_id)
    
    def _refresh_node_recursive(self, node, target_mod_id: str):
        """Recursively update node labels matching the target module ID"""
        node_id_str = str(node._id)
        if node_id_str in self.node_map and self.node_map[node_id_str] == target_mod_id:
            self._update_node_label(node, target_mod_id)
        for child in node.children:
            self._refresh_node_recursive(child, target_mod_id)


class SetupApp(App):
    """Main Textual Application"""
    
    CSS = """
    Screen {
        layout: horizontal;
    }
    
    #tree-panel {
        width: 55%;
        border: solid green;
        padding: 1;
        overflow-y: auto;
    }
    
    #info-panel {
        width: 45%;
        layout: vertical;
    }
    
    #selected-box {
        height: 50%;
        border: solid cyan;
        padding: 1;
    }
    
    #info-box {
        height: 50%;
        border: solid yellow;
        padding: 1;
    }
    
    SelectedList {
        height: 100%;
        overflow-y: auto;
    }
    
    SelectedList > ListItem {
        padding: 0 1;
    }
    
    SelectedList:focus > ListItem.--highlight {
        background: $accent;
    }
    
    InfoPanel {
        height: 100%;
    }

    InfoPanel:focus {
        background: $accent 10%;
    }
    
    Footer {
        background: $primary-background;
    }
    """
    
    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("escape", "quit", "Quit", show=False),
        Binding("f5", "install", "Install(F5)"),
        Binding("p", "load_preset", "Preset(p)"),
        Binding("d", "dry_run", "Simul(d)"),
        Binding("s", "save_preset", "Save(s)"),
        Binding("tab", "focus_next", "SwitchPanel", show=True),
    ]
    
    def __init__(self, preset: str = None, action: str = None, initial_selection: list = None):
        super().__init__()
        self.manager = ModuleManager()
        if initial_selection:
            self.manager.selected = set(initial_selection)
        self.preset_arg = preset
        self.action_mode = action
    
    def compose(self) -> ComposeResult:
        yield Header()
        with Horizontal():
            with Container(id="tree-panel"):
                yield ModuleTree(self.manager)
            with Container(id="info-panel"):
                with Container(id="selected-box"):
                    yield Label("[bold cyan]━━━ Selected (Space to remove) ━━━[/]")
                    yield SelectedList(self.manager)
                with Container(id="info-box"):
                    yield Label("[bold yellow]━━━ Module Info ━━━[/]")
                    yield InfoPanel(self.manager)
        yield Footer()
    
    def on_mount(self):
        self.title = "🐧 Linux Setup Assistant v4.0"
        self.sub_title = ""
        
        # Load preset from argument
        if self.preset_arg:
            preset_path = Path(self.preset_arg)
            if not preset_path.exists():
                preset_path = PRESETS_DIR / f"{self.preset_arg}.json"
            if preset_path.exists():
                self.manager.load_preset(preset_path)
                self.notify(f"Preset loaded: {preset_path.stem}")

        # Refresh selected list if there's an initial selection
        if self.manager.selected:
            try:
                self.query_one(SelectedList).refresh_list()
            except Exception:
                pass
        
        # Immediate action modes
        if self.action_mode == "execute":
            self.call_later(self.action_install)
        elif self.action_mode == "dry-run":
            self.call_later(self.action_dry_run)

    def action_quit(self):
        """Quit the application"""
        self.exit()

    def action_install(self):
        """Initiate installation"""
        if not self.manager.selected:
            self.notify("No modules selected!", severity="warning")
            return
        
        install_list = self.manager.resolve_dependencies()
        selected_items = list(self.manager.selected)
        self.exit(result=("execute", install_list, selected_items))

    def action_dry_run(self):
        """Initiate simulation (Dry Run)"""
        if not self.manager.selected:
            self.notify("No modules selected!", severity="warning")
            return
        
        install_list = self.manager.resolve_dependencies()
        selected_items = list(self.manager.selected)
        self.exit(result=("dry-run", install_list, selected_items))

    def action_save_preset(self):
        """Save current selection as a new preset"""
        if not self.manager.selected:
            self.notify("No modules selected!", severity="warning")
            return
        
        selected_items = list(self.manager.selected)
        self.exit(result=("save", [], selected_items))

    def action_load_preset(self):
        """Preset cycle (Quick selection)"""
        presets = list(PRESETS_DIR.glob("*.json"))
        if presets:
            self.notify("Press 'p' multiple times to cycle presets")


def save_preset(selected_items: list[str], preset_name: str = None):
    """Save the selected items into a preset JSON file"""
    from datetime import datetime
    
    if not preset_name:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        preset_name = f"custom_{timestamp}"
    
    preset_data = {
        "name": preset_name,
        "description": f"Auto-generated preset ({datetime.now().strftime('%Y-%m-%d %H:%M')})",
        "modules": []
    }
    
    for item in sorted(selected_items):
        if ":" in item:
            mod_id, version = item.split(":", 1)
            preset_data["modules"].append({
                "id": mod_id,
                "params": {"version": version}
            })
        else:
            preset_data["modules"].append({"id": item})
    
    preset_path = PRESETS_DIR / f"{preset_name}.json"
    preset_path.write_text(json.dumps(preset_data, indent=2, ensure_ascii=False))
    print(f"✅ Preset saved: {preset_path}")
    return preset_path


def run_installation(install_list: list[str], selected_items: list[str] = None, dry_run: bool = False):
    """Execute the installation sequence in the terminal"""
    print("\n" + "=" * 50)
    print(f"📦 Installation Sequence ({'Simulation' if dry_run else 'Actual Installation'})")
    print("=" * 50)
    
    # Detail installation plan
    for i, item in enumerate(install_list, 1):
        mod_id = item.split(":")[0]
        variant = item.split(":")[1] if ":" in item else ""
        
        # Search for module metadata
        meta_found = False
        for meta_file in MODULES_DIR.rglob("meta.json"):
            try:
                meta = json.loads(meta_file.read_text())
                if meta.get("id") == mod_id:
                    name = meta.get("name", mod_id)
                    install_script = meta_file.parent / "install.sh"
                    
                    if dry_run:
                        print(f"  {i}. {name} ({mod_id})")
                        if install_script.exists():
                            cmd = f"bash {install_script}"
                            if variant:
                                cmd += f" {variant}"
                            print(f"     ➜ Command: {cmd}")
                            if variant:
                                print(f"     ➜ Env: VERSION={variant}")
                        else:
                            print(f"     ⚠️  Warning: Installation script missing ({install_script})")
                    else:
                        print(f"  {i}. {name} ({mod_id})")
                    
                    meta_found = True
                    break
            except Exception:
                continue
        
        if not meta_found:
            print(f"  {i}. {item} (⚠️ Metadata not found)")

    print()
    
    if dry_run:
        print("🔍 Simulation Mode - No actual changes made")
        return
    
    # Suggest saving current selection as preset
    if selected_items:
        try:
            save = input("Would you like to save this selection as a preset before installing? (y/N): ").strip().lower()
            if save == 'y':
                name = input("Preset Name (Enter for auto-gen): ").strip() or None
                save_preset(selected_items, name)
        except KeyboardInterrupt:
            print("\n\n⚠️ Cancelled.")
            return
    
    print("\n🚀 Starting installation... (Ctrl+C to abort)")
    print("-" * 50)
    
    # Execution
    results = []
    start_total = time.time()
    cancelled = False
    
    try:
        for item in install_list:
            mod_id = item.split(":")[0]
            variant = item.split(":")[1] if ":" in item else ""
            
            # Find module path
            found = False
            for meta_file in MODULES_DIR.rglob("meta.json"):
                try:
                    meta = json.loads(meta_file.read_text())
                    if meta.get("id") == mod_id:
                        install_script = meta_file.parent / "install.sh"
                        if install_script.exists():
                            print(f"\n{'='*50}")
                            print(f">>> Installing [{meta.get('name', mod_id)}]...")
                            if variant:
                                print(f"    variant: {variant}")
                            print("=" * 50)
                            
                            # Pass variant as environment variable
                            env = dict(os.environ)
                            if variant:
                                env["VERSION"] = variant
                                env["VARIANT"] = variant
                            
                            start_mod = time.time()
                            
                            # Use subprocess.Popen for real-time output
                            process = subprocess.Popen(
                                ["bash", str(install_script), variant] if variant else ["bash", str(install_script)],
                                env=env,
                                cwd=meta_file.parent,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT,
                                text=True,
                                bufsize=1
                            )
                            
                            output_log = []
                            # Stream output
                            for line in process.stdout:
                                print(line, end='')
                                output_log.append(line)
                            
                            process.wait()
                            result_code = process.returncode
                            duration = time.time() - start_mod
                            
                            # Analyze results (check for idempotency skip)
                            full_output = "".join(output_log)
                            is_skipped = False
                            if result_code == 0:
                                if "already installed" in full_output.lower() or "이미 설치됨" in full_output:
                                    is_skipped = True
                            
                            if is_skipped:
                                status = "SKIPPED"
                            elif result_code == 0:
                                status = "SUCCESS"
                            else:
                                status = "FAILED"
                                
                            results.append({
                                "id": mod_id,
                                "name": meta.get("name", mod_id),
                                "status": status,
                                "duration": duration
                            })

                            if result_code != 0:
                                print(f"❌ Failed: {mod_id}")
                            elif is_skipped:
                                print(f"⏭️  Skipped: {mod_id} (Already installed)")
                            else:
                                print(f"✅ Completed: {mod_id}")
                            found = True
                        break
                except Exception as e:
                    print(f"⚠️ Error: {e}")
            
            if not found:
                print(f"⚠️ Module not found: {mod_id}")
                results.append({
                    "id": mod_id,
                    "name": mod_id,
                    "status": "NOT_FOUND",
                    "duration": 0
                })
                
    except KeyboardInterrupt:
        cancelled = True
        print("\n")
        print("=" * 50)
        print("⚠️ Cancelled by user.")
        print("=" * 50)
    
    total_duration = time.time() - start_total
    
    # Summary Report
    print("\n\n")
    print("=" * 60)
    print(f"📊 Installation Summary Report (Total Duration: {total_duration:.1f}s)")
    print("=" * 60)
    print(f"{ 'Module ID':<20} | {'Status':<10} | {'Duration':<10}")
    print("-" * 60)
    
    success_count = 0
    fail_count = 0
    skip_count = 0
    
    for res in results:
        status_icon = "✅ SUCCESS"
        if res["status"] == "FAILED": status_icon = "❌ FAILED"
        elif res["status"] == "SKIPPED": status_icon = "⏭️  SKIPPED"
        elif res["status"] == "NOT_FOUND": status_icon = "⚠️ MISSING"
        
        print(f"{res['id']:<20} | {status_icon:<10} | {res['duration']:.1f}s")
        
        if res["status"] == "SUCCESS":
            success_count += 1
        elif res["status"] == "SKIPPED":
            skip_count += 1
        else:
            fail_count += 1
            
    print("-" * 60)
    if cancelled:
        print("⚠️  Installation Aborted.")
    else:
        print(f"✨ Overall Results: Success {success_count} / Skipped {skip_count} / Failed {fail_count}")
    print("=" * 60)
    print()
    
    if dry_run:
        input("Press Enter to return to menu...")


def main():
    import argparse
    import signal
    
    # Graceful SIGINT (Ctrl+C) handling
    def signal_handler(sig, frame):
        print("\n\n⚠️ Cancelled.")
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    
    parser = argparse.ArgumentParser(description="Linux Setup Assistant")
    parser.add_argument("--preset", "-p", help="Preset name or path")
    parser.add_argument("--execute", "--run", action="store_true", help="Run installation immediately")
    parser.add_argument("--dry-run", action="store_true", help="Simulate installation")
    args = parser.parse_args()
    
    action_arg = None
    if args.execute:
        action_arg = "execute"
    elif args.dry_run:
        action_arg = "dry-run"
    
    preset_arg = args.preset
    current_selection = None
    
    while True:
        app = SetupApp(preset=preset_arg, action=action_arg, initial_selection=current_selection)
        result = app.run()
        
        # Reset arguments after first run
        action_arg = None
        preset_arg = None
        
        if not result:
            break
            
        mode, install_list, selected_items = result
        current_selection = selected_items # Preserve current selection
        
        if mode == "save":
            print("\n" + "=" * 50)
            name = input("Preset Name (Enter for auto-gen): ").strip() or None
            save_preset(selected_items, name)
            input("\n✅ Saved. Press Enter to return to selection screen...")
        elif mode == "execute":
            run_installation(install_list, selected_items, dry_run=False)
            break
        elif mode == "dry-run":
            run_installation(install_list, selected_items, dry_run=True)
            print("\n" + "=" * 50)
            input("🔍 Simulation complete. Press Enter to return to selection screen...")



if __name__ == "__main__":
    main()