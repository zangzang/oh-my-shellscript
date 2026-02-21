#!/bin/bash
set -e

# Load Library
if ! command -v ui_log_info &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

if [ -z "${OS_ID:-}" ]; then
    detect_os
fi

ui_log_info "Installing essential CLI tools..."

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    # Ubuntu/Debian specific packages
    PACKAGES=(jq tree htop btop ncdu mc ripgrep fd-find fzf vim nano bat)
    
    # Eza repository for Ubuntu
    if ! command -v eza &>/dev/null; then
        ui_log_info "Adding eza repository..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg --batch --yes
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo apt update
    fi
    PACKAGES+=(eza)
    
    install_packages "${PACKAGES[@]}"

elif [[ "$OS_ID" == "fedora" ]]; then
    # Fedora uses different package names
    # eza is not in default Fedora repos, install via cargo or skip
    PACKAGES=(jq tree htop btop ncdu mc ripgrep fd-find fzf vim-enhanced nano bat)
    install_packages "${PACKAGES[@]}"
    
    # Try to install eza from cargo if available
    if command -v cargo &>/dev/null; then
        ui_log_info "Installing eza via cargo..."
        cargo install eza || ui_log_warn "Failed to install eza"
    else
        ui_log_info "eza not available in Fedora repos. Install rust first for eza."
    fi
else
    ui_log_warn "Unsupported OS: $OS_ID - trying default package names"
    install_packages jq tree htop fzf vim nano
fi

# Verification
if command -v jq &>/dev/null || command -v vim &>/dev/null; then
    ui_log_success "CLI tools installation complete."
else
    ui_log_error "Critical CLI tools (jq, vim) not found. Installation may have failed."
    exit 1
fi

# Configure FZF in .bashrc
if command -v fzf &>/dev/null; then
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "FZF.*Configuration" "$HOME/.bashrc"; then
            cat <<'BASHRC_FZF' >> ~/.bashrc

# =============================================================================
# FZF Configuration
# =============================================================================

if command -v fzf &> /dev/null; then
    # FZF 색상 및 레이아웃
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    
    # FZF 명령어 설정
    if command -v fdfind &> /dev/null; then
        export FZF_DEFAULT_COMMAND="fdfind --type file --hidden --follow --exclude .git"
        export FZF_CTRL_T_COMMAND="fdfind --type file --hidden --follow --exclude .git"
        export FZF_ALT_C_COMMAND="fdfind --type directory --hidden --follow --exclude .git"
        export FZF_CTRL_T_OPTS="--preview 'batcat --style=numbers --color=always --line-range :500 {}' --bind 'ctrl-/:change-preview-window(down|hidden|)' 2>/dev/null || echo {}"
    fi
fi
BASHRC_FZF
            ui_log_success ".bashrc FZF configured"
        fi
    fi

    #Configure FZF in .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "FZF.*Configuration" "$HOME/.zshrc"; then
            cat <<'ZSHRC_FZF' >> ~/.zshrc

# =============================================================================
# FZF Configuration
# =============================================================================

if command -v fzf &> /dev/null; then
    # FZF 기본 설정 파일 로드
    [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
    
    # FZF 색상 및 레이아웃
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    
    # FZF 명령어 설정
    if command -v fdfind &> /dev/null; then
        export FZF_DEFAULT_COMMAND="fdfind --type file --hidden --follow --exclude .git"
        export FZF_CTRL_T_COMMAND="fdfind --type file --hidden --follow --exclude .git"
        export FZF_ALT_C_COMMAND="fdfind --type directory --hidden --follow --exclude .git"
        export FZF_CTRL_T_OPTS="--preview 'batcat --style=numbers --color=always --line-range :500 {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
        export FZF_ALT_C_OPTS="--preview 'eza --tree --level=1 --icons {}' 2>/dev/null || echo {}"
    fi
fi
ZSHRC_FZF
            ui_log_success ".zshrc FZF configured"
        fi
    fi
fi
