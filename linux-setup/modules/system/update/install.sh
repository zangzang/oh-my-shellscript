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

ui_log_info "🔄 Running system update..."

if [[ "$OS_ID" == "fedora" ]]; then
    # DNF Optimization
    if ! grep -q "fastestmirror=True" /etc/dnf/dnf.conf 2>/dev/null; then
        ui_log_info "⚡ Applying DNF optimization (fastestmirror, max_parallel_downloads)..."
        echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
        echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    fi
    
    ui_log_info "Cleaning DNF cache and refreshing metadata..."
    sudo dnf clean all
    
    ui_log_info "Executing system upgrade (Fedora)..."
    # Using --best and --allowerasing to handle dependency conflicts more gracefully,
    # but dnf will still protect essential packages like systemd-udev.
    if ! sudo dnf upgrade -y --refresh; then
        ui_log_warn "Standard upgrade failed. Trying with --best --allowerasing..."
        sudo dnf upgrade -y --best --allowerasing
    fi
    
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    # Ubuntu/Debian
    # Check gpgv
    if ! command -v gpgv >/dev/null 2>&1; then
        ui_log_info "Installing gpgv..."
        sudo apt-get install -y --no-install-recommends gpgv || sudo apt-get install -y --no-install-recommends gnupg
    fi
    ui_log_info "Updating package lists..."
    sudo apt update
    ui_log_info "Executing system upgrade (Ubuntu/Debian)..."
    sudo apt upgrade -y
else
    ui_log_warn "⚠️  OS not supported for auto-update: $OS_ID"
fi

ui_log_success "System update complete."
