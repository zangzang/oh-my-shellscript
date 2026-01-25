#!/bin/bash
set -e

echo "🧪 Testing Java installation..."

# Initialize SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    set +u
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    set -u
fi

# Check Java
if ! command -v java &>/dev/null; then
    echo "❌ 'java' command not found."
    exit 1
fi

if ! command -v javac &>/dev/null; then
    echo "❌ 'javac' command not found."
    exit 1
fi

# Check version
echo "✅ Java Version: $(java -version 2>&1 | head -n 1)"
echo "✅ Javac Version: $(javac -version 2>&1)"

# Create test directory (linux-setup/test/dev.java/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.java"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📝 Creating Hello.java..."
cat > Hello.java << 'EOF'
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello World from Java!");
    }
}
EOF

echo "🔨 Compiling..."
if ! javac Hello.java; then
    echo "❌ Compilation failed"
    exit 1
fi

echo "🚀 Running..."
OUTPUT=$(java Hello 2>&1)

cd ~

# Verify result
if echo "$OUTPUT" | grep -q "Hello World"; then
    echo "✅ Output: $OUTPUT"
    echo "✅ Java Test Passed!"
    echo "📁 Test file: $TEST_DIR/Hello.java"
    exit 0
else
    echo "❌ Unexpected output: $OUTPUT"
    echo "📁 Test file: $TEST_DIR/Hello.java"
    exit 1
fi