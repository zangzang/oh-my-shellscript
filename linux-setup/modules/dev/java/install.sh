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

# Check OS
if [ -z "${OS_ID:-}" ]; then
    detect_os
fi

# Package mapping function
get_java_package() {
    local ver="$1"
    local os="${OS_ID:-unknown}"
    
    if [[ "$os" == "fedora" ]]; then
        case "$ver" in
            8) echo "java-1.8.0-openjdk-devel" ;;
            11) echo "java-11-openjdk-devel" ;;
            17) echo "java-17-openjdk-devel" ;;
            21) echo "java-21-openjdk-devel" ;;
            22) echo "java-22-openjdk-devel" ;;
            25) echo "java-latest-openjdk-devel" ;; # Fedora might not have 25 yet, using latest
            *) echo "java-latest-openjdk-devel" ;;
        esac
    elif [[ "$os" == "ubuntu" || "$os" == "debian" || "$os" == "pop" || "$os" == "linuxmint" ]]; then
        case "$ver" in
            8) echo "openjdk-8-jdk" ;;
            11) echo "openjdk-11-jdk" ;;
            17) echo "openjdk-17-jdk" ;;
            21) echo "openjdk-21-jdk" ;;
            25) echo "openjdk-25-jdk" ;; # Might not exist
            *) echo "default-jdk" ;;
        esac
    else
        echo ""
    fi
}

PKG_NAME=$(get_java_package "$VERSION")

# 1. Try System Package Manager
INSTALLED_NATIVE=false
if [[ -n "$PKG_NAME" ]]; then
    echo "📦 Attempting to install Java $VERSION via system package ($PKG_NAME)..."
    if install_packages "$PKG_NAME"; then
        echo "✅ Java installation complete (System Package)"
        INSTALLED_NATIVE=true
    else
        echo "⚠️  System package installation failed. Switching to fallback mode."
    fi
fi

if [[ "$INSTALLED_NATIVE" == "true" ]]; then
    exit 0
fi

# 2. Fallback: SDKMAN
echo "🔄 Attempting installation via SDKMAN..."

export SDKMAN_DIR="$HOME/.sdkman"
export sdkman_auto_answer=true

# Install SDKMAN if missing
if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    echo "Downloading and installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
fi

# Initialize SDKMAN
set +u
source "$SDKMAN_DIR/bin/sdkman-init.sh"
set -u

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
    CANDIDATE=$(sdk list java | grep -Eo "${VERSION}\.[0-9]+\.[0-9]+-tem" | head -1 || true)
    if [[ -n "$CANDIDATE" ]]; then
        sdk_version="$CANDIDATE"
    fi
fi

echo "Installing Java via SDKMAN: $sdk_version"
sdk install java "$sdk_version" <<<"y"
