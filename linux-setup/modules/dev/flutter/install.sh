#!/bin/bash
set -e

# Load Library
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

echo "🦋 Installing Flutter SDK..."

# 1. Install Linux Flutter dependencies
PKGS=("curl" "git" "unzip" "xz-utils")
if [[ "$OS_ID" == "fedora" ]]; then
    PKGS+=("mesa-libGLU" "clang" "cmake" "ninja-build" "pkg-config" "gtk3-devel")
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    PKGS+=("libglu1-mesa" "clang" "cmake" "ninja-build" "pkg-config" "libgtk-3-dev")
fi

install_packages "${PKGS[@]}"

# 2. Download Flutter SDK (Git Clone)
FLUTTER_ROOT="$HOME/flutter"
if [[ -d "$FLUTTER_ROOT" ]]; then
    echo "✅ Flutter SDK already exists: $FLUTTER_ROOT"
    echo "   Checking for updates..."
    cd "$FLUTTER_ROOT"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git pull
    else
        echo "⚠️  $FLUTTER_ROOT is not a git repository. Manual check required."
    fi
else
    echo "📥 Cloning Flutter SDK (stable)..."
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_ROOT"
fi

# 3. Temp PATH setup
export PATH="$FLUTTER_ROOT/bin:$PATH"

# 4. Initialize and Pre-cache
echo "⚙️  Downloading Flutter binaries and initializing..."
flutter precache

# 5. Check Status
echo "🏥 Running Flutter Doctor..."
# Android licenses are handled in dev.android module.
# Do not abort script on doctor warnings.
flutter doctor || echo "⚠️  Some warnings found in Flutter Doctor. Please check above."

echo "🎉 Flutter installation complete."