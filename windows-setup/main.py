import os
import sys
import subprocess
from pathlib import Path
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

def main():
    if not ensure_textual():
        sys.exit(1)
        
    # Import TUI after installation check
    from core.tui import SetupApp
    
    root_dir = Path(__file__).parent.resolve()
    manager = module.ModuleManager(root_dir)
    
    app = SetupApp(manager)
    result = app.run()
    
    if result:
        mode, install_list = result
        
        # Execute
        logger.section(f"Execution: {mode}")
        dry_run = (mode == "dry-run")
        
        for item in install_list:
            mod_id = item.split(":")[0]
            variant = item.split(":")[1] if ":" in item else None
            
            mod = manager.get_module(mod_id)
            if mod:
                try:
                    mod.install(variant=variant, dry_run=dry_run)
                except Exception as e:
                    logger.error(f"Failed {mod_id}: {e}")

if __name__ == "__main__":
    main()
