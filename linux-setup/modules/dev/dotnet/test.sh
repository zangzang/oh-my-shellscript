#!/bin/bash
set -e

echo "🧪 Testing .NET installation..."

# Setup .NET PATH
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"

if ! command -v dotnet &>/dev/null; then
    echo "❌ 'dotnet' command not found."
    exit 1
fi

echo "✅ .NET Version: $(dotnet --version)"

# Create test directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="/tmp/dotnet-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📝 Creating Hello World console app..."
dotnet new console -n HelloWorld >/dev/null 2>&1

cd HelloWorld

echo "🚀 Building and running..."
# Use --nologo to remove banner
OUTPUT=$(dotnet run --nologo 2>&1 || true)

# Verify output (case insensitive hello)
if echo "$OUTPUT" | grep -qi "hello"; then
    echo "✅ Output: $(echo "$OUTPUT" | head -n 1)"
    echo "✅ .NET Test Passed!"
    rm -rf "$TEST_DIR"
    exit 0
else
    echo "❌ Execution validation failed"
    echo "📝 Actual Output: $OUTPUT"
    rm -rf "$TEST_DIR"
    exit 1
fi
