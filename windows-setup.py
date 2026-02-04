#!/usr/bin/env python3
"""
Windows Development Environment Setup
Modular installation system for Windows development tools
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path

# Add windows-setup to path for imports
SCRIPT_DIR = Path(__file__).parent.resolve()
WINDOWS_SETUP_DIR = SCRIPT_DIR / "windows-setup"
sys.path.insert(0, str(WINDOWS_SETUP_DIR))

from core import logger, module

def ensure_textual():
    try:
        import textual
        return True
    except ImportError:
        pass
        
    print("Installing textual library for TUI...")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "textual"], check=True)
        print("Textual installed successfully.")
        return True
    except Exception as e:
        print(f"Failed to install textual: {e}")
        return False

def load_preset(preset_path: Path) -> list:
    """Load module list from preset file"""
    import json
    try:
        with open(preset_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            return data.get("modules", [])
    except Exception as e:
        logger.error(f"Failed to load preset: {e}")
        return []

def run_installation(manager: module.ModuleManager, modules_list: list, dry_run: bool = False):
    """Execute installation for given modules"""
    mode = "Dry Run" if dry_run else "Execute"
    logger.section(f"Installation Mode: {mode}")
    
    for item in modules_list:
        mod_id = item.split(":")[0]
        variant = item.split(":")[1] if ":" in item else None
        
        mod = manager.get_module(mod_id)
        if mod:
            try:
                mod.install(variant=variant, dry_run=dry_run)
            except Exception as e:
                logger.error(f"Failed {mod_id}: {e}")
        else:
            logger.warning(f"Module not found: {mod_id}")

def main():
    parser = argparse.ArgumentParser(
        description="Windows Development Environment Setup",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Interactive TUI mode (default)
  python windows-setup.py

  # Install with preset
  python windows-setup.py --preset fullstack-dev --execute

  # Dry run with preset
  python windows-setup.py --preset node-dev --dry-run

  # Install specific modules
  python windows-setup.py --modules dev.git,dev.nodejs --execute
        """
    )
    
    parser.add_argument("--preset", "-p", help="Preset name or path to preset JSON file")
    parser.add_argument("--modules", "-m", help="Comma-separated module IDs (e.g., dev.git,dev.nodejs)")
    parser.add_argument("--execute", "--run", action="store_true", help="Run installation immediately")
    parser.add_argument("--dry-run", action="store_true", help="Simulate installation without making changes")
    parser.add_argument("--no-gui", action="store_true", help="Run in CLI mode (requires --preset or --modules)")
    
    args = parser.parse_args()
    
    # root_dir is windows-setup directory
    root_dir = WINDOWS_SETUP_DIR
    manager = module.ModuleManager(root_dir)
    
    # CLI Mode (no GUI)
    if args.no_gui or args.preset or args.modules:
        modules_to_install = []
        
        # Load from preset
        if args.preset:
            preset_name = args.preset
            preset_path = None
            
            # Check if it's a file path
            if Path(preset_name).exists():
                preset_path = Path(preset_name)
            else:
                # Try to find preset in presets directory
                presets_dir = root_dir / "presets"
                if not preset_name.endswith('.json'):
                    preset_name += '.json'
                preset_path = presets_dir / preset_name
            
            if preset_path and preset_path.exists():
                modules_to_install = load_preset(preset_path)
                logger.info(f"Loaded preset: {preset_path.name}")
            else:
                logger.error(f"Preset not found: {args.preset}")
                sys.exit(1)
        
        # Load from module list
        elif args.modules:
            modules_to_install = [m.strip() for m in args.modules.split(',')]
            logger.info(f"Loading modules: {', '.join(modules_to_install)}")
        
        else:
            logger.error("--no-gui requires either --preset or --modules")
            parser.print_help()
            sys.exit(1)
        
        # Determine execution mode
        if args.execute:
            run_installation(manager, modules_to_install, dry_run=False)
        elif args.dry_run:
            run_installation(manager, modules_to_install, dry_run=True)
        else:
            # Just list modules
            logger.info("Modules to install (use --execute or --dry-run):")
            for mod in modules_to_install:
                print(f"  - {mod}")
        
        return
    
    # TUI Mode (default)
    if not ensure_textual():
        sys.exit(1)
        
    # Import TUI after installation check
    from core.tui import SetupApp
    
    app = SetupApp(manager)
    result = app.run()
    
    if result:
        mode, install_list = result
        
        # Execute
        dry_run = (mode == "dry-run")
        run_installation(manager, install_list, dry_run=dry_run)

if __name__ == "__main__":
    main()
