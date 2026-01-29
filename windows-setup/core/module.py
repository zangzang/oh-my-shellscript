import os
import json
import subprocess
import sys
from pathlib import Path
from core import logger, package_manager

class Module:
    def __init__(self, path):
        self.path = Path(path)
        self.meta_path = self.path / "meta.json"
        self.install_py = self.path / "install.py"
        self.install_ps1 = self.path / "install.ps1"
        self.meta = self._load_meta()
        
        self.id = self.meta.get("id", "unknown")
        self.name = self.meta.get("name", self.path.name)
        self.description = self.meta.get("description", "")
        self.category = self.meta.get("category", "uncategorized")
        self.requires = self.meta.get("requires", [])
        self.variants = self.meta.get("variants", {}) # Dictionary or List? Linux-setup uses keys of variants dict
        self.configuration = self.meta.get("configuration", {})
        
        self.winget_id = self.meta.get("wingetId")
        self.install_method = self.meta.get("installMethod")
        self.ps_module = self.meta.get("psModule")

    def _load_meta(self):
        if not self.meta_path.exists():
            return {}
        try:
            return json.loads(self.meta_path.read_text(encoding="utf-8"))
        except Exception as e:
            logger.error(f"Failed to load meta for {self.path}: {e}")
            return {}

    def install(self, variant=None, dry_run=False):
        logger.section(f"Installing: {self.name} ({self.id}) {f'[v{variant}]' if variant else ''}")
        
        # Handle variants (e.g., Java 17 vs 21)
        # If variant is specified, look up specific config
        target_winget = self.winget_id
        
        if variant and isinstance(self.variants, dict) and variant in self.variants:
            v_data = self.variants[variant]
            if "wingetId" in v_data:
                target_winget = v_data["wingetId"]
            # Add other variant overrides here if needed

        # Priority 1: install.py
        if self.install_py.exists():
            self._run_python_installer(dry_run, variant)
        
        # Priority 2: install.ps1 (Legacy support)
        elif self.install_ps1.exists():
            self._run_powershell_installer(dry_run, variant)
            
        # Priority 3: Winget
        elif target_winget:
            package_manager.install_winget(target_winget, f"{self.name} {variant if variant else ''}", dry_run)

        # Priority 4: PS Module
        elif self.install_method == "psmodule":
            mod_name = self.ps_module
            if not mod_name:
                mod_name = self.id.split(".")[-1]
            package_manager.install_ps_module(mod_name, dry_run=dry_run)
            
        else:
            logger.warn(f"No installation method found for {self.id}")

    def _run_python_installer(self, dry_run, variant):
        if dry_run:
            logger.dry_run(f"Execute Python script: {self.install_py}")
            return

        try:
            env = os.environ.copy()
            if dry_run:
                env["DRY_RUN"] = "1"
            if variant:
                env["MODULE_VARIANT"] = variant
            
            cmd = [sys.executable, str(self.install_py)]
            # If install.py accepts args, we can pass them. 
            # For now, let's assume env vars or no args.
            
            result = subprocess.run(cmd, env=env, check=True)
            if result.returncode == 0:
                logger.success(f"Installed {self.name} via script")
        except Exception as e:
            logger.error(f"Installation script failed for {self.name}: {e}")

    def _run_powershell_installer(self, dry_run, variant):
        if dry_run:
            logger.dry_run(f"Execute PowerShell script: {self.install_ps1}")
            return

        try:
            cmd = ["pwsh", "-File", str(self.install_ps1)]
            if dry_run:
                cmd.append("-DryRun")
            if variant:
                cmd.extend(["-Variant", variant])
            
            result = subprocess.run(cmd, check=True)
            if result.returncode == 0:
                logger.success(f"Installed {self.name} via PowerShell")
        except Exception as e:
            logger.error(f"PowerShell script failed for {self.name}: {e}")

class ModuleManager:
    def __init__(self, root_dir):
        self.root_dir = Path(root_dir)
        self.modules_dir = self.root_dir / "modules"
        self.config_dir = self.root_dir / "config"
        self.presets_dir = self.root_dir / "presets"
        
        self.modules = {}
        self.categories = {}
        self.selected = set() # Set of "id" or "id:variant"
        self.context_items = {} # id:variant -> bool (checked state)

        self._load_categories()
        self._load_modules()

    def _load_categories(self):
        cat_file = self.config_dir / "categories.json"
        if cat_file.exists():
            try:
                self.categories = json.loads(cat_file.read_text(encoding='utf-8'))
            except:
                self.categories = {}
        else:
            self.categories = {}

    def _load_modules(self):
        if not self.modules_dir.exists():
            return

        for meta_file in self.modules_dir.rglob("meta.json"):
            mod = Module(meta_file.parent)
            if not mod.id:
                continue

            self.modules[mod.id] = mod
            
            # Category Logic matching linux-setup
            cat_path = mod.category.split("/")
            top_cat = cat_path[0]

            if top_cat not in self.categories:
                self.categories[top_cat] = {
                    "name": top_cat.capitalize(),
                    "order": 999,
                    "modules": []
                }

            target = self.categories[top_cat]
            
            if len(cat_path) > 1:
                sub_cat = cat_path[1]
                if "subcategories" not in target:
                    target["subcategories"] = {}
                if sub_cat not in target["subcategories"]:
                    target["subcategories"][sub_cat] = {"name": sub_cat.capitalize(), "modules": []}
                
                if mod.id not in target["subcategories"][sub_cat]["modules"]:
                    target["subcategories"][sub_cat]["modules"].append(mod.id)
            else:
                if "modules" not in target:
                    target["modules"] = []
                if mod.id not in target["modules"]:
                    target["modules"].append(mod.id)

    def get_module(self, mod_id):
        base_id = mod_id.split(":")[0]
        return self.modules.get(base_id)

    def toggle(self, item_id):
        if item_id in self.selected:
            self.selected.discard(item_id)
            self.context_items[item_id] = False
        else:
            self.selected.add(item_id)
            self.context_items[item_id] = True

    def remove_from_context(self, item_id):
        self.selected.discard(item_id)
        if item_id in self.context_items:
            del self.context_items[item_id]

    def resolve_dependencies(self):
        result = []
        visited = set()

        def resolve(item_id):
            base_id = item_id.split(":")[0]
            if item_id in visited or base_id in visited:
                return
            
            visited.add(item_id) # Simplify logic: treat variant as unique for visited? 
            # Ideally we check if base_id installed.
            
            mod = self.get_module(base_id)
            if mod:
                for dep in mod.requires:
                    # Resolve dep (assume no variant for dep for now)
                    resolve(dep)
            
            result.append(item_id)

        for item in sorted(self.selected):
            resolve(item)
        return result

    def load_preset(self, preset_file, clear_selection=True):
        if clear_selection:
            self.selected.clear()
            self.context_items.clear()

        try:
            data = json.loads(preset_file.read_text(encoding='utf-8'))
            for entry in data.get("modules", []):
                # Preset format: { "modules": [ "id", ... ] } OR { "modules": [ {"id": "...", "params": {...}}, ... ] }
                # My previous presets were simple lists of IDs. linux-setup uses objects.
                # Let's support both.
                if isinstance(entry, str):
                    mod_id = entry
                    version = ""
                    selected = True
                else:
                    mod_id = entry.get("id")
                    version = entry.get("params", {}).get("version", "")
                    selected = entry.get("params", {}).get("selected", True)

                key = f"{mod_id}:{version}" if version else mod_id
                
                self.context_items[key] = selected
                if selected:
                    self.selected.add(key)
                elif not clear_selection:
                    self.selected.discard(key)
        except Exception as e:
            logger.error(f"Failed to load preset {preset_file}: {e}")

    def unload_preset(self, preset_file):
        try:
            data = json.loads(preset_file.read_text(encoding='utf-8'))
            for entry in data.get("modules", []):
                mod_id = entry if isinstance(entry, str) else entry.get("id")
                version = ""
                if not isinstance(entry, str):
                    version = entry.get("params", {}).get("version", "")
                
                key = f"{mod_id}:{version}" if version else mod_id
                self.selected.discard(key)
                self.context_items[key] = False
        except:
            pass