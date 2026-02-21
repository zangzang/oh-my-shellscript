#!/bin/bash
set -e

# Source library
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# path to lib/distro.sh: modules/system/build-tools -> ../../.. -> lib
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

# =============================================================================
# Check if build-tools were installed in the last 24 hours
# =============================================================================

BUILD_TIMESTAMP_FILE="$HOME/.build_timestamp"
CURRENT_TIME=$(date +%s)
SKIP_BUILD=false

if [[ -f "$BUILD_TIMESTAMP_FILE" ]]; then
    LAST_BUILD_TIME=$(cat "$BUILD_TIMESTAMP_FILE")
    TIME_DIFF=$((CURRENT_TIME - LAST_BUILD_TIME))
    ONE_DAY_SECONDS=86400
    
    if [[ $TIME_DIFF -lt $ONE_DAY_SECONDS ]]; then
        HOURS=$((TIME_DIFF / 3600))
        MINUTES=$(((TIME_DIFF % 3600) / 60))
        echo "⏭️  Build tools were already installed ${HOURS}h ${MINUTES}m ago. Skipping (24h interval)"
        SKIP_BUILD=true
    fi
fi

if [[ "$SKIP_BUILD" == "true" ]]; then
    exit 0
fi

echo "Installing build tools..."

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    # Debian/Ubuntu 계열은 배포판 버전/미러 상태에 따라 일부 패키지가 없을 수 있음
    # 필수 패키지는 엄격 설치, 선택 패키지는 실패해도 계속 진행
    sudo apt update -y || true

    install_packages \
        curl wget git unzip zip build-essential \
        ca-certificates gnupg \
        cmake pkg-config autoconf automake libtool

    optional_pkgs=(software-properties-common apt-transport-https)
    for pkg in "${optional_pkgs[@]}"; do
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            sudo apt install -y "$pkg" || echo "⚠️ Optional package install failed: $pkg"
        else
            echo "ℹ️ Optional package not available on this distro: $pkg"
        fi
    done
elif [[ "$OS_ID" == "fedora" ]]; then
    # Fedora uses different package names
    install_packages \
        curl wget git unzip zip \
        dnf-plugins-core ca-certificates gnupg2 \
        cmake pkgconf-pkg-config autoconf automake libtool \
        gcc gcc-c++ make
    # Install development tools group
    sudo dnf groupinstall -y "Development Tools" || true
else
    echo "⚠️ Unsupported OS: $OS_ID"
    exit 1
fi

echo "✅ Build tools installation complete"
# Save timestamp for 24-hour caching
date +%s > "$BUILD_TIMESTAMP_FILE"