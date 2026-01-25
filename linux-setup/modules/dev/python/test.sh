#!/bin/bash
set -e

echo "🧪 Testing Python installation..."

# Check Python existence
if ! command -v python &>/dev/null && ! command -v python3 &>/dev/null; then
    echo "❌ 'python' command not found."
    exit 1
fi

# Determine Python command (prefer python3)
PYTHON_CMD="python3"
if ! command -v python3 &>/dev/null; then
    PYTHON_CMD="python"
fi

# Check version
echo "✅ Python Version: $($PYTHON_CMD --version)"

# Create test directory (linux-setup/test/dev.python/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.python"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"

# Run Hello World
echo "🚀 Running..."
OUTPUT=$($PYTHON_CMD -c "print('Hello World from Python!')" 2>&1)

# Verify result
if echo "$OUTPUT" | grep -q "Hello World"; then
    echo "✅ Output: $OUTPUT"
    echo "✅ Python Test Passed!"
    echo "📁 Test directory: $TEST_DIR"
    exit 0
else
    echo "❌ Unexpected output: $OUTPUT"
    echo "📁 Test directory: $TEST_DIR"
    exit 1
fi