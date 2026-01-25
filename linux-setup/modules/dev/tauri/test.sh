#!/bin/bash
set -e

MODULE_ID="dev.tauri"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_DIR="$WORKSPACE_ROOT/test/$MODULE_ID"

# Initialize Node.js PATH (NVM)
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    nounset_was_on=0
    if [[ "$-" =~ u ]]; then
        nounset_was_on=1
        set +u
    fi
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"
    if [[ $nounset_was_on -eq 1 ]]; then
        set -u
    fi
fi

# Initialize Rust PATH
if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
fi

mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Clean up
echo "🧹 Cleaning up test files..."
rm -rf "$TEST_DIR"/*

echo "🧪 Testing Tauri installation..."

# Check Rust
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust (cargo) not installed."
    exit 1
fi
echo "✅ Rust Version: $(rustc --version | head -n 1)"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not installed."
    exit 1
fi
echo "✅ Node.js Version: $(node --version)"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm not installed."
    exit 1
fi
echo "✅ npm Version: $(npm --version)"

# Check Tauri dependencies (via pkg-config)
echo "🔍 Checking Tauri dependencies..."
for pkg in gtk+-3.0 webkit2gtk-4.1 glib-2.0; do
    if pkg-config --exists "$pkg" 2>/dev/null; then
        echo "✅ $pkg installed"
    else
        echo "❌ $pkg not installed"
        exit 1
    fi
done

# Check Tauri CLI
echo "📦 Checking Tauri CLI..."
if ! command -v cargo-tauri &> /dev/null; then
    echo "❌ Tauri CLI (cargo-tauri) not installed. Please install 'dev.tauri' module."
    exit 1
fi
echo "✅ Tauri CLI ready"

# Create simple Tauri project
echo "📝 Creating Tauri project..."
# Run create-tauri-app in non-interactive mode
npm create tauri-app@latest tauri-hello -- --yes --manager npm --template vanilla

if [[ ! -d "tauri-hello" ]]; then
    echo "❌ Project creation failed"
    exit 1
fi

cd tauri-hello

# Verify project structure (Skipping full build to save time)
echo "🔨 Verifying project structure..."
if [[ -f "src-tauri/Cargo.toml" ]] && [[ -f "package.json" ]]; then
    echo "✅ Tauri project structure valid"
    echo "✅ Tauri Test Passed!"
    echo "📁 Project location: $TEST_DIR/tauri-hello"
    exit 0
else
    echo "❌ Invalid project structure"
    exit 1
fi