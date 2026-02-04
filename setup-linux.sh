#!/bin/bash
#
# OMSS (Oh My Shell Script) - Quick Launcher
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$SCRIPT_DIR/linux-setup"

# Check if textual is installed
check_textual() {
    python3 -c "import textual" 2>/dev/null
}

# Ensure dependencies are installed
ensure_deps() {
    # Check pip
    if ! python3 -m pip --version &>/dev/null; then
        echo "📦 pip not found. Installing..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y python3-pip python3-venv
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y python3-pip
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm python-pip
        else
            echo "❌ Could not install pip. Please install python3-pip manually."
            exit 1
        fi
    fi
    
    # Check textual
    if ! check_textual; then
        echo "📦 Installing textual library..."
        python3 -m pip install --user textual -q
    fi
}

# Main
if ! check_textual; then
    ensure_deps
fi

cd "$SCRIPT_DIR"
exec python3 linux-setup.py "$@"
