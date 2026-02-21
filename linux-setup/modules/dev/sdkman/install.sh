#!/bin/bash
set -e

export SDKMAN_DIR="$HOME/.sdkman"
export sdkman_auto_answer=true

if [ -d "$SDKMAN_DIR" ]; then
    echo "SDKMAN is already installed"
else
    echo "Installing SDKMAN..."
    if curl -s "https://get.sdkman.io?rcupdate=false" | bash; then
        echo "SDKMAN installation complete"
    else
        echo "SDKMAN installation failed"
        exit 1
    fi
    
    # Initialize SDKMAN
    if [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
        nounset_was_on=0
        case "$-" in *u*) nounset_was_on=1 ;; esac
        set +u
        # shellcheck disable=SC1090
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        if (( nounset_was_on )); then set -u; fi
    fi
fi

echo "SDKMAN setup complete"

# Configure .bashrc
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "SDKMAN_DIR" "$HOME/.bashrc"; then
        cat <<'BASHRC_SDKMAN' >> ~/.bashrc

# SDKMAN (Java/Maven/Gradle)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
BASHRC_SDKMAN
        echo "✓ .bashrc configured"
    fi
fi

# Configure .zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "SDKMAN_DIR" "$HOME/.zshrc"; then
        cat <<'ZSHRC_SDKMAN' >> ~/.zshrc

# SDKMAN (Java/Maven/Gradle)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
ZSHRC_SDKMAN
        echo "✓ .zshrc configured"
    fi
fi
