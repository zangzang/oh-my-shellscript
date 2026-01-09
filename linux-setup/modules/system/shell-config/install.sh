#!/bin/bash
set -e

echo ".zshrc 설정 파일 생성 중..."

# 기존 .zshrc 백업
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)" 2>/dev/null || true
    echo "기존 .zshrc 백업됨"
fi

# .zshrc 생성
cat <<'ZSHRC' > ~/.zshrc
# =============================================================================
# Zsh Configuration
# =============================================================================

# --- PATH ---
export PATH=$HOME/.local/bin:/usr/local/bin:$PATH

# =============================================================================
# Development Tools Environment Variables
# =============================================================================

# .NET
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# Rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# SDKMAN (Java/Maven/Gradle)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# NVM (Node.js)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Pyenv (Python)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv &> /dev/null; then
    eval "$(pyenv init -)"
fi

# 자바 편의 설정 (-v 명령어 지원)
java() {
    if [[ "$1" == "-v" ]]; then
        command java -version
    else
        command java "$@"
    fi
}
export -f java 2>/dev/null || true

# =============================================================================
# Aliases
# =============================================================================

alias ll='ls -lah'
alias update='sudo apt update && sudo apt upgrade -y'

# Modern CLI alternatives (Overwriting standard commands can break scripts)
command -v batcat &> /dev/null && alias cat='batcat'
command -v fdfind &> /dev/null && alias fd='fdfind'
command -v rg &> /dev/null && alias grep='rg'
command -v eza &> /dev/null && {
    alias ls='eza --icons'
    alias la='eza -la --icons'
    alias lt='eza --tree --level=2 --icons'
}
alias du='ncdu'

# =============================================================================
# FZF Configuration
# =============================================================================

if command -v fzf &> /dev/null; then
    # FZF 기본 설정 파일 로드
    [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
    
    # FZF 색상 및 레이아웃
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    
    # FZF 명령어 설정 (전체 타입 이름 사용)
    export FZF_DEFAULT_COMMAND="fdfind --type file --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="fdfind --type file --hidden --follow --exclude .git"
    export FZF_ALT_C_COMMAND="fdfind --type directory --hidden --follow --exclude .git"
    
    # 미리보기 설정
    export FZF_CTRL_T_OPTS="--preview 'batcat --style=numbers --color=always --line-range :500 {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=1 --icons {}'"
fi

# =============================================================================
# FZF Custom Functions
# =============================================================================

# Ctrl+F: 파일 검색 후 에디터로 열기
fzf-edit-file() {
    local file
    file=$(fdfind --type file --hidden --follow --exclude .git | fzf --preview 'batcat --style=numbers --color=always {}')
    if [[ -n "$file" ]]; then
        ${EDITOR:-vim} "$file"
    fi
}
zle -N fzf-edit-file
bindkey '^F' fzf-edit-file

# fh: 히스토리 검색
fh() {
    print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}

# fkill: 프로세스 검색 후 종료
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    if [ "x$pid" != "x" ]; then
        echo $pid | xargs kill -${1:-9}
    fi
}

# =============================================================================
# Oh My Posh
# =============================================================================

if command -v oh-my-posh &> /dev/null; then
    if [ -f "$HOME/.config/oh-my-posh/catppuccin_mocha.omp.json" ]; then
        eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/catppuccin_mocha.omp.json)"
    fi
fi

# =============================================================================
# Fastfetch
# =============================================================================

if command -v fastfetch &> /dev/null; then
    fastfetch
fi
ZSHRC

echo ".zshrc 설정 완료"

# .bashrc 설정 추가 (ZSHRC의 주요 내용을 BASHRC에도 반영)
if [ -f "$HOME/.bashrc" ]; then
    # 중복 삽입 방지 확인
    if ! grep -q "SDKMAN_DIR" "$HOME/.bashrc"; then
        cat <<'BASHRC' >> ~/.bashrc

# --- Linux Setup Assistant Paths ---
export PATH=$HOME/.local/bin:/usr/local/bin:$PATH

# SDKMAN/NVM/Pyenv
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv &> /dev/null; then eval "$(pyenv init -)"; fi

# 자바 편의 설정
java() {
    if [[ "$1" == "-v" ]]; then command java -version
    else command java "$@"; fi
}; export -f java
BASHRC
        echo ".bashrc 설정 추가 완료"
    fi
fi

echo "변경사항 적용을 위해 터미널을 재시작하거나 'source ~/.zshrc' 또는 'source ~/.bashrc'를 실행하세요"
