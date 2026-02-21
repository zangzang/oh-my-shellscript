#!/bin/bash
set -e
VERSION="${1:-17}"

# Load Library
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # .../modules/dev/java -> ../../../lib
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

check_java_installed() {
    local required_ver="$1"
    
    if ! command -v java &>/dev/null; then
        return 1
    fi
    
    # Get installed Java version (e.g., "17.0.2" -> "17")
    local installed_ver
    installed_ver=$(java -version 2>&1 | head -1 | grep -oP '(?<=version ")([0-9]+)' || echo "")
    
    if [[ -z "$installed_ver" ]]; then
        return 1
    fi
    
    echo "🔍 Detected Java version: $installed_ver (requested: $required_ver)"
    
    if [[ "$installed_ver" == "$required_ver" ]]; then
        return 0
    fi
    
    return 1
}

# Check if already installed
if check_java_installed "$VERSION"; then
    echo "✅ Java $VERSION is already installed."
    java -version 2>&1 | head -3
    exit 0
fi

echo "🔄 Installing Java via SDKMAN dependency..."

export SDKMAN_DIR="$HOME/.sdkman"
export sdkman_auto_answer=true

if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    echo "❌ SDKMAN is not initialized. Please ensure dependency dev.sdkman is installed first."
    exit 1
fi

# Initialize SDKMAN (disable strict mode for SDKMAN compatibility)
set +eu
export SDKMAN_OFFLINE_MODE=false
source "$SDKMAN_DIR/bin/sdkman-init.sh"

if ! type sdk >/dev/null 2>&1; then
    echo "❌ Failed to initialize SDKMAN"
    exit 1
fi

# Calculate SDKMAN version string
sdk_version="$VERSION"
if [[ "$VERSION" =~ ^[0-9]+$ ]]; then
    # Default to Temurin identifier
    sdk_version="$VERSION-tem" 
    
    echo "Searching for Java $VERSION in SDKMAN..."
    
    # Simple pattern matching for Temurin version
    CANDIDATE=$(sdk list java 2>/dev/null | grep -Eo "${VERSION}\.[0-9]+\.[0-9]+-tem" | head -1 || true)
    if [[ -n "$CANDIDATE" ]]; then
        sdk_version="$CANDIDATE"
    fi
fi

echo "Installing Java via SDKMAN: $sdk_version"
sdk install java "$sdk_version" <<< "y" || {
    echo "❌ Failed to install Java via SDKMAN"
    exit 1
}

echo "✅ Java installation complete (SDKMAN)"
