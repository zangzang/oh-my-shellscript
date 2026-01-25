#!/bin/bash
set -e

# Load Library
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

fix_tmp_dir() {
    if [[ ! -d /tmp ]]; then
        sudo mkdir -p /tmp
    fi
    local tmp_mode
    tmp_mode=$(stat -c '%a' /tmp 2>/dev/null || echo '')
    if [[ "$tmp_mode" != "1777" ]]; then
        echo "⚠️  Permissions for /tmp are abnormal ($tmp_mode). Restoring to 1777."
        sudo chmod 1777 /tmp
    fi
    if ! sudo -u "${SUDO_USER:-$USER}" sh -c 'mktemp -p /tmp >/dev/null' 2>/dev/null; then
        echo "❌ Cannot create temporary files in /tmp. Check mount/permissions for /tmp."
        exit 1
    fi
}

fix_tmp_dir

echo "🔄 Running system update..."

if [[ "$OS_ID" == "fedora" ]]; then
    # DNF Optimization
    if ! grep -q "fastestmirror=True" /etc/dnf/dnf.conf 2>/dev/null; then
        echo "⚡ Applying DNF optimization (fastestmirror, max_parallel_downloads)..."
        echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
        echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    fi
    sudo dnf update -y
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    # Ubuntu/Debian
    # Check gpgv
    if ! command -v gpgv >/dev/null 2>&1; then
        echo "Installing gpgv..."
        sudo apt-get install -y --no-install-recommends gpgv || sudo apt-get install -y --no-install-recommends gnupg
    fi
    sudo apt update
    sudo apt upgrade -y
else
    echo "⚠️  OS not supported for auto-update: $OS_ID"
fi
