#!/bin/bash
set -e

# Initialize SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
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
fi

MODULE_ID="dev.gradle"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_DIR="$WORKSPACE_ROOT/test/$MODULE_ID"

mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "🧪 Testing Gradle installation..."

# Check Gradle Version
if ! command -v gradle &> /dev/null; then
    echo "❌ Gradle not installed."
    exit 1
fi

GRADLE_VERSION=$(gradle --version | grep "Gradle" | head -n 1)
echo "✅ Gradle Version: $GRADLE_VERSION"

# Clean up
if [[ -d "hello-gradle" ]] || [[ -f "settings.gradle" ]]; then
    echo "🧹 Cleaning up existing project files..."
    rm -rf hello-gradle settings.gradle* gradle* build.gradle* .gradle
fi

# Create Gradle Project
echo "📦 Creating Gradle project..."
gradle init --type java-application --dsl groovy --test-framework junit --project-name hello-gradle --package com.example --no-split-project --no-incubating --use-defaults

cd hello-gradle

# Build
echo "🔨 Building..."
gradle build -q

# Run
echo "🚀 Running..."
OUTPUT=$(gradle run -q --console=plain)
echo "✅ Output: $OUTPUT"

if [[ "$OUTPUT" == "Hello World!"* ]]; then
    echo "✅ Gradle Test Passed!"
    echo "📁 Project location: $TEST_DIR/hello-gradle"
    exit 0
else
    echo "❌ Gradle Test Failed"
    exit 1
fi