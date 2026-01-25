#!/bin/bash
set -e

export SDKMAN_DIR="$HOME/.sdkman"
export sdkman_auto_answer=true

if [ -d "$SDKMAN_DIR" ]; then
    echo "SDKMAN is already installed"
    # Initialize SDKMAN to check Maven, Gradle
    if [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
        nounset_was_on=0
        case "$-" in *u*) nounset_was_on=1 ;; esac
        set +u
        # shellcheck disable=SC1090
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        if (( nounset_was_on )); then set -u; fi
    fi
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

# Install Maven
if ! command -v mvn &>/dev/null; then
    echo "Installing Maven..."
    nounset_was_on=0
    case "$-" in *u*) nounset_was_on=1 ;; esac
    set +u
    set +e
    sdk install maven <<<"y"
    install_rc=$?
    set -e
    if [[ $install_rc -eq 0 || $install_rc -eq 1 ]]; then
        echo "✅ Maven installation complete"
    else
        echo "⚠️  Maven installation command failed (exit=$install_rc)"
    fi
    if (( nounset_was_on )); then set -u; fi
else
    echo "✅ Maven already installed"
fi

# Install Gradle
if ! command -v gradle &>/dev/null; then
    echo "Installing Gradle..."
    nounset_was_on=0
    case "$-" in *u*) nounset_was_on=1 ;; esac
    set +u
    set +e
    sdk install gradle <<<"y"
    install_rc=$?
    set -e
    if [[ $install_rc -eq 0 || $install_rc -eq 1 ]]; then
        echo "✅ Gradle installation complete"
    else
        echo "⚠️  Gradle installation command failed (exit=$install_rc)"
    fi
    if (( nounset_was_on )); then set -u; fi
else
    echo "✅ Gradle already installed"
fi

echo "SDKMAN, Maven, Gradle setup complete"