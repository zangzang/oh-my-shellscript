#!/bin/bash
set -e

echo "🧪 Testing NVM installation..."

# Initialize NVM
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "❌ nvm.sh not found in $NVM_DIR"
    exit 1
fi

\. "$NVM_DIR/nvm.sh"

# Check NVM
if ! command -v nvm &>/dev/null; then
    echo "❌ 'nvm' command not found."
    exit 1
fi

# Check version
NVM_VERSION=$(nvm --version)
echo "✅ NVM Version: $NVM_VERSION"

# Test nvm functionality (e.g., list remote versions)
echo "🚀 Testing 'nvm ls-remote'..."
if nvm ls-remote | tail -n 5; then
    echo "✅ nvm ls-remote succeeded"
    echo "✅ NVM Test Passed!"
    exit 0
else
    echo "❌ nvm ls-remote failed"
    exit 1
fi
