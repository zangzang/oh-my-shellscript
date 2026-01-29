import sys
import os
import json
import subprocess

# Path hack to find core
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))
from core import logger, system

def install():
    # 1. Check prerequisites
    if not system.is_installed("dotnet"):
        logger.error(".NET SDK is not installed. Skipping Playwright.")
        sys.exit(1)

    logger.info("Setting up Playwright...")

    # 2. Install Playwright CLI
    try:
        result = subprocess.run(["dotnet", "tool", "list", "--global"], capture_output=True, text=True)
        if "microsoft.playwright.cli" in result.stdout.lower():
            logger.success("Playwright CLI already installed.")
        else:
            logger.info("Installing Playwright CLI...")
            subprocess.run(["dotnet", "tool", "install", "--global", "Microsoft.Playwright.CLI"], check=True)
            logger.success("Playwright CLI installed.")
    except Exception as e:
        logger.error(f"Failed to check/install Playwright CLI: {e}")
        sys.exit(1)

    # 3. Configure Env Var
    meta_path = os.path.join(os.path.dirname(__file__), "meta.json")
    browsers_path = r"C:\Shared\PlaywrightBrowsers" # Default
    
    if os.path.exists(meta_path):
        try:
            with open(meta_path, 'r') as f:
                data = json.load(f)
                browsers_path = data.get("configuration", {}).get("BROWSERS_PATH", browsers_path)
        except:
            pass
            
    # Create dir
    if not os.path.exists(browsers_path):
        try:
            os.makedirs(browsers_path)
            logger.success(f"Created directory: {browsers_path}")
        except Exception as e:
            logger.error(f"Failed to create directory {browsers_path}: {e}")
            sys.exit(1)

    # Set Env
    system.set_env("PLAYWRIGHT_BROWSERS_PATH", browsers_path)
    os.environ["PLAYWRIGHT_BROWSERS_PATH"] = browsers_path

    # 4. Install Browsers
    logger.info("Installing Playwright browsers...")
    try:
        # playwright is now a command (if path updated)
        # We might need to call via dotnet tool run or assume it's in path
        # If just installed, PATH might not be updated in this process yet.
        # But 'dotnet tool run playwright' works? No, it's global.
        # It's usually in %USERPROFILE%\.dotnet\tools
        
        tool_path = os.path.expandvars(r"%USERPROFILE%\.dotnet\tools\playwright.exe")
        cmd = ["playwright", "install"]
        if os.path.exists(tool_path):
             cmd = [tool_path, "install"]
        
        subprocess.run(cmd, check=True)
        logger.success("Playwright browsers installed.")
    except Exception as e:
        logger.error(f"Failed to install browsers: {e}")

if __name__ == "__main__":
    install()
