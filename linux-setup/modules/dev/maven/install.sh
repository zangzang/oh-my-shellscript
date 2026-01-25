#!/bin/bash
set -e

export SDKMAN_DIR="$HOME/.sdkman"
export sdkman_auto_answer=true

if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    echo "SDKMAN is not installed: $SDKMAN_DIR"
    echo "Please install 'dev.sdkman' module first."
    exit 1
fi

# Initialize SDKMAN
nounset_was_on=0
if [[ "$-" =~ u ]]; then
    nounset_was_on=1
    set +u
fi

# shellcheck disable=SC1091
source "$SDKMAN_DIR/bin/sdkman-init.sh"

if [[ $nounset_was_on -eq 1 ]]; then
    set -u
fi

echo "Installing Maven..."
sdk install maven

echo "✅ Maven installation complete"