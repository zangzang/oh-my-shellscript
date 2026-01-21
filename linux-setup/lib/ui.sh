#!/bin/bash

# Define colors for non-gum fallback or custom formatting
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
COLOR_GRAY='\033[0;90m'

# Aliases for compatibility (easy-setup.sh 등에서 사용)
BLUE="$COLOR_BLUE"
YELLOW="$COLOR_YELLOW"
RED="$COLOR_RED"
GREEN="$COLOR_GREEN"
NC="$COLOR_RESET" # No Color

# Check if gum is available
HAS_GUM=false
if command -v gum >/dev/null 2>&1; then
    HAS_GUM=true
fi

ui_header() {
    local title="$1"
    local subtitle="$2"
    if [ "$HAS_GUM" = true ]; then
        clear
        gum style --foreground 212 --border-foreground 212 --border double --align center --width 60 --margin "1 1" \
            "$title" "$subtitle"
    else
        echo -e "${COLOR_CYAN}=== $title ===${COLOR_RESET}"
        echo -e "${COLOR_GRAY}$subtitle${COLOR_RESET}\n"
    fi
}

ui_log_info() {
    local msg="$1"
    if [ "$HAS_GUM" = true ]; then
        gum style --foreground 39 "ℹ $msg"
    else
        echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $msg"
    fi
}

ui_log_success() {
    local msg="$1"
    if [ "$HAS_GUM" = true ]; then
        gum style --foreground 82 "✔ $msg"
    else
        echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $msg"
    fi
}

ui_log_warn() {
    local msg="$1"
    if [ "$HAS_GUM" = true ]; then
        gum style --foreground 220 "⚠ $msg"
    else
        echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $msg"
    fi
}

ui_log_error() {
    local msg="$1"
    if [ "$HAS_GUM" = true ]; then
        gum style --foreground 196 "✖ $msg"
    else
        echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $msg"
    fi
}

# Run a command with a spinner
# Usage: ui_spin "Message" command arg1 arg2 ...
ui_spin() {
    local msg="$1"
    shift
    local cmd=($@)

    if [ "$HAS_GUM" = true ]; then
        gum spin --spinner dot --title "$msg" -- "${cmd[@]}"
    else
        echo -e "${COLOR_YELLOW}⏳ $msg...${COLOR_RESET}"
        "${cmd[@]}"
    fi
}

ui_confirm() {
    local msg="$1"
    if [ "$HAS_GUM" = true ]; then
        if gum confirm "$msg"; then
            return 0
        else
            return 1
        fi
    else
        read -p "$msg (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Wrapper for gum choose
# Usage: ui_menu "Header" "option1" "option2" ...
ui_menu() {
    local header="$1"
    shift
    local options=($@)
    
    if [ "$HAS_GUM" = true ]; then
        # Gum choose expects input via stdin for list
        printf "%s\n" "${options[@]}" | gum choose --header "$header" --height 15
    else
        # Very basic fallback
        echo -e "${COLOR_CYAN}$header${COLOR_RESET}"
        select opt in "${options[@]}"; do
            if [ -n "$opt" ]; then
                echo "$opt"
                break
            fi
        done
    fi
}
