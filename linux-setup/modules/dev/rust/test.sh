#!/bin/bash
set -e

echo "🧪 Testing Rust installation..."

# Setup Cargo PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Check Rust existence
if ! command -v cargo &>/dev/null; then
    echo "❌ 'cargo' command not found."
    exit 1
fi

if ! command -v rustc &>/dev/null; then
    echo "❌ 'rustc' command not found."
    exit 1
fi

# Check version
echo "✅ Rust Version: $(rustc --version)"
echo "✅ Cargo Version: $(cargo --version)"

# Create test directory (linux-setup/test/dev.rust/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.rust"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Cleanup
if [[ -d "hello" ]]; then
    echo "🧹 Cleaning up existing project..."
    rm -rf hello
fi

echo "📝 Creating Cargo project..."
if ! cargo new hello --bin --quiet; then
    echo "❌ Project creation failed"
    exit 1
fi

cd hello

echo "🚀 Running..."
OUTPUT=$(cargo run --quiet 2>&1)

cd ~

# Verify result
if echo "$OUTPUT" | grep -q "Hello"; then
    echo "✅ Output: $OUTPUT"
    echo "✅ Rust Test Passed!"
    echo "📁 Project location: $TEST_DIR/hello"
    exit 0
else
    echo "❌ Unexpected output: $OUTPUT"
    echo "📁 Project location: $TEST_DIR/hello"
    exit 1
fi