#!/bin/bash
#
# OMSS (Oh My Shell Script) - Quick Launcher
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/linux-setup"
exec python3 setup.py "$@"
