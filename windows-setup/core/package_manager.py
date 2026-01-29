import subprocess
import shutil
from core import logger

def is_installed(command):
    return shutil.which(command) is not None

def install_winget(package_id, name=None, dry_run=False):
    if name is None:
        name = package_id

    if dry_run:
        logger.dry_run(f"Winget Install: {name} (ID: {package_id})")
        return True

    logger.info(f"Installing {name} (ID: {package_id})...")

    # Check if already installed via winget list
    # Note: winget list can be slow.
    
    cmd = ["winget", "install", "--id", package_id, "--accept-package-agreements", "--accept-source-agreements", "--silent"]
    
    try:
        # We can try 'list' first or just run install. Install is usually idempotent-ish or fails gracefully.
        # But 'winget install' fails if already installed? No, it usually says "already installed".
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            logger.success(f"Installed {name}")
            return True
        elif "No newer version found" in result.stdout:
             logger.success(f"{name} is already installed (latest).")
             return True
        else:
            logger.error(f"Failed to install {name}")
            logger.error(result.stdout)
            logger.error(result.stderr)
            return False
    except Exception as e:
        logger.error(f"Error running winget: {e}")
        return False

def install_ps_module(name, scope="CurrentUser", dry_run=False):
    if dry_run:
        logger.dry_run(f"Install PS Module: {name}")
        return True

    logger.info(f"Installing PowerShell module: {name}...")
    
    # Check if installed
    check_cmd = ["pwsh", "-NoProfile", "-Command", f"if (Get-Module -ListAvailable -Name {name}) {{ exit 0 }} else {{ exit 1 }}"]
    if subprocess.run(check_cmd).returncode == 0:
        logger.success(f"PS Module {name} is already installed.")
        return True

    # Install
    cmd = ["pwsh", "-NoProfile", "-Command", f"Install-Module -Name {name} -Scope {scope} -Force -AllowClobber"]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            logger.success(f"Installed PS Module {name}")
            return True
        else:
            logger.error(f"Failed to install PS Module {name}: {result.stderr}")
            return False
    except Exception as e:
        logger.error(f"Error installing PS module: {e}")
        return False
