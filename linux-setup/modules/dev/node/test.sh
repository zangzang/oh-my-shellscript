#!/bin/bash
set -e

echo "🧪 Testing Node.js installation..."

# Initialize NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Check Node.js
if ! command -v node &>/dev/null; then
    echo "❌ 'node' command not found."
    exit 1
fi

# Check version
echo "✅ Node.js Version: $(node --version)"
echo "✅ npm Version: $(npm --version)"

# Create test directory (linux-setup/test/dev.node/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.node"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📝 Creating hello.js..."
cat > hello.js << 'EOF'
console.log('Hello World from Node.js!');
EOF

echo "🚀 Running..."
OUTPUT=$(node hello.js 2>&1)

cd ~

# Verify result
if echo "$OUTPUT" | grep -q "Hello World"; then
    echo "✅ Output: $OUTPUT"
    echo "✅ Node.js Test Passed!"
    echo "📁 Test file: $TEST_DIR/hello.js"
    exit 0
else
    echo "❌ Unexpected output: $OUTPUT"
    echo "📁 Test file: $TEST_DIR/hello.js"
    exit 1
fi