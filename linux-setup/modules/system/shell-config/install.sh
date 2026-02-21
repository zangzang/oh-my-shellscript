#!/bin/bash
set -e

echo ".bashrc 설정 파일 수정 중..."

# 기존 .bashrc 백업
if [ -f "$HOME/.bashrc" ]; then
    cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%s)" 2>/dev/null || true
    echo "기존 .bashrc 백업됨"
fi

# .bashrc에 기본 설정 추가 (중복 삽입 방지)
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "Linux Setup Assistant" "$HOME/.bashrc"; then
        cat <<'BASHRC' >> ~/.bashrc

# =============================================================================
# Linux Setup Assistant - Basic Configuration
# =============================================================================

# --- PATH ---
export PATH=$HOME/.local/bin:/usr/local/bin:$PATH

# =============================================================================
# Basic Aliases
# =============================================================================

alias ll='ls -lah'
alias update='sudo apt update && sudo apt upgrade -y'

# Modern CLI alternatives (if installed)
command -v batcat &> /dev/null && alias cat='batcat'
command -v fdfind &> /dev/null && alias fd='fdfind'
command -v rg &> /dev/null && alias grep='rg'
command -v eza &> /dev/null && {
    alias ls='eza --icons'
    alias la='eza -la --icons'
    alias lt='eza --tree --level=2 --icons'
}
command -v ncdu &> /dev/null && alias du='ncdu'
BASHRC
        echo ".bashrc 기본 설정 추가 완료"
    fi
fi

# .zshrc가 있으면 기본 설정 추가
if [ -f "$HOME/.zshrc" ]; then
    echo ".zshrc 설정 파일 추가 수정 중..."
    
    if ! grep -q "Linux Setup Assistant" "$HOME/.zshrc"; then
        cat <<'ZSHRC' >> ~/.zshrc

# =============================================================================
# Linux Setup Assistant - Basic Configuration
# =============================================================================

# --- PATH ---
export PATH=$HOME/.local/bin:/usr/local/bin:$PATH

# =============================================================================
# Basic Aliases
# =============================================================================

alias ll='ls -lah'
alias update='sudo apt update && sudo apt upgrade -y'

# Modern CLI alternatives (if installed)
command -v batcat &> /dev/null && alias cat='batcat'
command -v fdfind &> /dev/null && alias fd='fdfind'
command -v rg &> /dev/null && alias grep='rg'
command -v eza &> /dev/null && {
    alias ls='eza --icons'
    alias la='eza -la --icons'
    alias lt='eza --tree --level=2 --icons'
}
command -v ncdu &> /dev/null && alias du='ncdu'
ZSHRC
        echo ".zshrc 기본 설정 추가 완료"
    fi
fi

echo ""
echo "============================================================"
echo "쉘 기본 설정 완료!"
echo "============================================================"
echo "변경사항 적용을 위해 다음 중 하나를 실행하세요:"
echo "  - 터미널 재시작"
echo "  - source ~/.bashrc"
echo "  - source ~/.zshrc   (zsh 사용자의 경우)"
echo "============================================================"

