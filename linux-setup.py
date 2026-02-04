#!/usr/bin/env python3
"""
Linux Setup Assistant v4.0 - Launcher from root directory
"""

import sys
from pathlib import Path

# Add linux-setup to path and run the actual setup
SCRIPT_DIR = Path(__file__).parent.resolve()
LINUX_SETUP_DIR = SCRIPT_DIR / "linux-setup"

# Change to linux-setup directory and run setup.py
sys.path.insert(0, str(LINUX_SETUP_DIR))
import os
os.chdir(str(LINUX_SETUP_DIR))

# Import and run the main setup
from setup import main

if __name__ == "__main__":
    main()
