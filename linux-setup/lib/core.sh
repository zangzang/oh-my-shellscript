#!/bin/bash

# Load Libraries (Handle relative paths)
CURRENT_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_LIB_DIR/distro.sh"
source "$CURRENT_LIB_DIR/ui.sh"

# Check and install essential utilities (jq, fzf, gum, awk)
ensure_utils() {
    local needed=()
    command -v jq >/dev/null || needed+=("jq")
    command -v fzf >/dev/null || needed+=("fzf")
    command -v gum >/dev/null || needed+=("gum")
    command -v awk >/dev/null || needed+=("gawk")

    if [ ${#needed[@]} -gt 0 ]; then
        ui_log_info "Installing essential utilities: ${needed[*]}"
        
        if [ "$OS_ID" == "ubuntu" ] || [ "$OS_ID" == "debian" ] || [ "$OS_ID" == "pop" ] || [ "$OS_ID" == "linuxmint" ]; then
            sudo mkdir -p /etc/apt/keyrings
            if [ ! -f /etc/apt/keyrings/charm.gpg ]; then
                curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            fi
            if [ ! -f /etc/apt/sources.list.d/charm.list ]; then
                echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
            fi
            sudo apt update && sudo apt install -y "${needed[@]}"

        elif [ "$OS_ID" == "fedora" ]; then
            if [ ! -f /etc/yum.repos.d/charm.repo ]; then
                echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
            fi
            sudo dnf install -y "${needed[@]}"
        
        else
            echo "Auto-installation not supported for OS: $OS_ID"
            echo "Please manually install: ${needed[*]}"
            exit 1
        fi
        
        # Update gum status
        if command -v gum >/dev/null 2>&1; then
            HAS_GUM=true
        fi
    fi
}

check_network() {
    ui_log_info "Checking network connection..."
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        ui_log_error "⚠️  Internet connection required."
        exit 1
    fi
    ui_log_success "Network connected"
}

check_os() {
    detect_os # from distro.sh
    if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "fedora" && "$OS_ID" != "debian" ]]; then
        ui_log_warn "⚠️  This script is optimized for Ubuntu/Debian and Fedora."
        echo -e "   Current system: ${OS_ID} ${OS_VERSION}"
        
        if ! ui_confirm "Do you want to continue?"; then
            exit 0
        fi
    fi
}

# Run module test
run_module_test() {
    local module_path="$1"
    local test_script="${module_path}/test.sh"
    
    if [ ! -f "$test_script" ]; then
        ui_log_warn "Test script missing: $test_script"
        return 1
    fi
    
    ui_log_info "Running test..."
    if bash "$test_script"; then
        ui_log_success "✅ Test Passed"
        return 0
    else
        ui_log_error "❌ Test Failed"
        return 1
    fi
}

# Robust npm global installation
npm_install_g() {
    local pkg=$1
    local bin_name=$(echo "$pkg" | sed 's/.*\///' | sed 's/@//')
    
    # Try to load NVM if available
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # Use a subshell to avoid affecting current set -e if we just want to load it
        \. "$NVM_DIR/nvm.sh" || true
    fi

    if ! command -v npm &>/dev/null; then
        ui_log_error "npm not found. Please install Node.js first."
        return 1
    fi

    ui_log_info "Installing global npm package: $pkg"
    
    # Check if we are in NVM environment (don't use sudo for NVM)
    if [[ "$PATH" == *"$NVM_DIR"* ]]; then
        ui_log_info "NVM detected. Installing without sudo..."
        if npm install -g "$pkg"; then
            ui_log_success "Successfully installed $pkg via NVM"
            return 0
        fi
    fi

    # Fallback to normal/sudo installation
    if npm install -g "$pkg" 2>/dev/null; then
        ui_log_success "Successfully installed $pkg"
        return 0
    else
        ui_log_warn "Permission denied or error. Trying with sudo..."
        if sudo npm install -g "$pkg" --unsafe-perm; then
            ui_log_success "Successfully installed $pkg with sudo"
            return 0
        else
            ui_log_error "Failed to install $pkg even with sudo."
            # Explicitly return 1 so set -e will catch it
            return 1
        fi
    fi
}

# Robust pip installation
pip_install() {
    local pkg=$1
    
    local pip_cmd="pip"
    if ! command -v pip &>/dev/null; then
        if command -v pip3 &>/dev/null; then
            pip_cmd="pip3"
        else
            ui_log_error "pip not found. Please install Python first."
            return 1
        fi
    fi

    ui_log_info "Installing python package: $pkg"
    if $pip_cmd install "$pkg"; then
        ui_log_success "Successfully installed $pkg"
        return 0
    else
        ui_log_warn "Failed to install $pkg. Trying with --user..."
        if $pip_cmd install --user "$pkg"; then
            ui_log_success "Successfully installed $pkg with --user"
            return 0
        else
            ui_log_warn "Trying with sudo..."
            if sudo -E $pip_cmd install "$pkg"; then
                ui_log_success "Successfully installed $pkg with sudo"
                return 0
            else
                ui_log_error "Failed to install $pkg even with sudo."
                return 1
            fi
        fi
    fi
}

# Legacy wrapper
log_info() { ui_log_info "$1"; }
log_success() { ui_log_success "$1"; }
log_warn() { ui_log_warn "$1"; }
log_error() { ui_log_error "$1"; }