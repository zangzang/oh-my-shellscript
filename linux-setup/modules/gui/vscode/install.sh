#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

# Check Linux native VSCode path
LINUX_CODE_BIN="/usr/bin/code"
if [[ ! -x "$LINUX_CODE_BIN" ]]; then
    # Check other potential paths
    if command -v code &>/dev/null; then
        potential_path=$(command -v code)
        if [[ "$potential_path" != /mnt/* ]]; then
            LINUX_CODE_BIN="$potential_path"
        fi
    fi
fi

# Install VSCode (if not present)
if [[ -x "$LINUX_CODE_BIN" ]]; then
    echo "✅ Linux VS Code is already installed: $LINUX_CODE_BIN"
else
    echo "📥 Installing Linux VS Code..."
    
    if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg

        sudo apt update
        sudo DEBIAN_FRONTEND=noninteractive apt install -y code
        
    elif [[ "$OS_ID" == "fedora" ]]; then
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
             echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
        fi
        sudo dnf install -y code
    else
        echo "❌ Unsupported OS: $OS_ID"
        exit 1
    fi
    LINUX_CODE_BIN="/usr/bin/code"
    echo "✅ Linux VS Code installation complete"
fi

# Install VSCode Extension Groups
install_vscode_extensions() {
    local -a profiles=()
    for p in "$@"; do
        [[ -n "$p" ]] && profiles+=("$p")
    done
    
    profiles=("base" "${profiles[@]}")
    echo "VSCode Extension Groups: ${profiles[*]}"
    
    # Use native Linux binary
    local code_cmd="$LINUX_CODE_BIN"
    if [[ ! -x "$code_cmd" ]]; then
        echo "❌ Linux 'code' binary not found. Cannot install extensions."
        return 1
    fi
    
    # Collect all extensions
    local -a all_extensions=()
    for profile in "${profiles[@]}"; do
        local ext_file="$SCRIPT_DIR/extensions/${profile}.json"
        if [[ -f "$ext_file" ]]; then
            while IFS= read -r ext; do
                [[ -n "$ext" ]] && all_extensions+=("$ext")
            done < <(jq -r '.extensions[]' "$ext_file" 2>/dev/null || true)
        else
            echo "⚠️  Extension group file not found: $ext_file"
        fi
    done
    
    if [[ ${#all_extensions[@]} -eq 0 ]]; then
        echo "No extensions to install."
        return
    fi
    
    local -a unique_extensions=($(printf '%s\n' "${all_extensions[@]}" | sort -u))
    echo "Attempting to install ${#unique_extensions[@]} extensions..."
    
    local installed=0
    for ext in "${unique_extensions[@]}"; do
        echo "Installing: $ext"
        if "$code_cmd" --install-extension "$ext" --force; then
            ((installed++)) || true
        else
            echo "❌ Failed to install extension: $ext"
        fi
    done
    
    echo "✅ VSCode extensions installed: ${installed} count"
}

# Handle profile arguments
if [[ $# -gt 0 ]]; then
    install_vscode_extensions "$@"
fi
