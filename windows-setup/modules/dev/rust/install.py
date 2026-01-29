import sys
import os
import urllib.request
import subprocess
import tempfile
import shutil

# Path hack to find core
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))
from core import logger, system

def install():
    if system.is_installed("rustc"):
        logger.success("Rust is already installed.")
        return

    logger.info("Installing Rust...")
    url = "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe"
    
    # Use standard temp dir
    fd, tmp_path = tempfile.mkstemp(suffix=".exe")
    os.close(fd)
    
    try:
        logger.info(f"Downloading {url}...")
        urllib.request.urlretrieve(url, tmp_path)
        
        logger.info("Running rustup-init.exe...")
        # -y for no prompts
        subprocess.run([tmp_path, "-y"], check=True)
        
        logger.success("Rust installed successfully.")
    except Exception as e:
        logger.error(f"Failed to install Rust: {e}")
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

if __name__ == "__main__":
    install()
