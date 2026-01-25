#!/bin/bash
set -e

# Load Library
if ! command -v ui_log_info &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../.." && pwd)/lib"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

ui_log_info "🧪 Testing Python installation..."

# Check Python existence
if ! command -v python &>/dev/null && ! command -v python3 &>/dev/null; then
    ui_log_error "'python' command not found."
    exit 1
fi

# Determine Python command (prefer python3)
PYTHON_CMD="python3"
if ! command -v python3 &>/dev/null; then
    PYTHON_CMD="python"
fi

# Check version
ui_log_info "Python Version: $($PYTHON_CMD --version)"

# Create test directory (linux-setup/test/dev.python/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.python"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"

# Run Hello World
ui_log_info "🚀 Running Hello World test..."
OUTPUT=$($PYTHON_CMD -c "print('Hello World from Python!')" 2>&1)

# Verify result
if echo "$OUTPUT" | grep -q "Hello World"; then
    ui_log_success "Output: $OUTPUT"
    ui_log_success "Python Test Passed!"
    exit 0
else
    ui_log_error "Unexpected output: $OUTPUT"
    exit 1
fi