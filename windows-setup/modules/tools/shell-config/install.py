import sys
import os
import subprocess

# Path hack to find core
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))
from core import logger, system

def install():
    logger.info("Configuring PowerShell Profile...")
    
    try:
        # Get Profile Path
        cmd = ["pwsh", "-NoProfile", "-Command", "echo $PROFILE"]
        profile_path = subprocess.check_output(cmd, text=True).strip()
        
        if not profile_path:
            logger.error("Could not determine $PROFILE path.")
            return

        profile_dir = os.path.dirname(profile_path)
        if not os.path.exists(profile_dir):
            os.makedirs(profile_dir)

        content = """
# Oh My Posh
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config $env:POSH_THEMES_PATH\jandedobbeleer.omp.json | Invoke-Expression
}

# Terminal Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# zoxide
if (Get-Command z -ErrorAction SilentlyContinue) {
    zoxide init powershell | Invoke-Expression
}

# PSReadLine
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# Aliases
Set-Alias g git
Set-Alias l ls
"""
        with open(profile_path, "w", encoding="utf-8") as f:
            f.write(content)
            
        logger.success(f"Updated PowerShell profile: {profile_path}")

    except Exception as e:
        logger.error(f"Failed to configure shell: {e}")

if __name__ == "__main__":
    install()
