#!/bin/bash
set -e

echo "🧪 Testing Docker installation..."

if ! command -v docker &>/dev/null; then
    echo "❌ 'docker' command not found."
    exit 1
fi

# Check WSL 2 environment
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi

# Check version
VERSION=$(docker --version)
echo "✅ Docker Version: $VERSION"

# Check daemon execution
if ! docker ps >/dev/null 2>&1; then
    if [ "$IS_WSL" = true ]; then
        echo "ℹ️  WSL 2 environment detected."
        echo "   Please verify that this distro (WSL Integration) is enabled in Docker Desktop settings on Windows."
    else
        echo "❌ Docker daemon is not running."
        echo "   Run 'sudo systemctl start docker' to start it."
    fi
    exit 1
fi

echo "✅ Docker daemon running"
echo "✅ Docker Test Passed!"
exit 0
