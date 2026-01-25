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

MODULE_ID="dev.maven"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_DIR="$WORKSPACE_ROOT/test/$MODULE_ID"

mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "🧪 Testing Maven installation..."

# Check Maven Version
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven not installed."
    exit 1
fi

MVN_VERSION=$(mvn --version | head -n 1)
echo "✅ Maven Version: $MVN_VERSION"

# Cleanup
if [[ -d "hello-maven" ]]; then
    echo "🧹 Cleaning up existing project..."
    rm -rf hello-maven
fi

# Create Maven Project
echo "📦 Creating Maven project..."
mvn archetype:generate \
    -DgroupId=com.example \
    -DartifactId=hello-maven \
    -DarchetypeArtifactId=maven-archetype-quickstart \
    -DarchetypeVersion=1.4 \
    -DinteractiveMode=false

cd hello-maven

# Build
echo "🔨 Building..."
mvn clean package -q

# Run
echo "🚀 Running..."
OUTPUT=$(java -cp target/hello-maven-1.0-SNAPSHOT.jar com.example.App)
echo "✅ Output: $OUTPUT"

if [[ "$OUTPUT" == "Hello World!"* ]]; then
    echo "✅ Maven Test Passed!"
    echo "📁 Project location: $TEST_DIR/hello-maven"
    exit 0
else
    echo "❌ Maven Test Failed"
    exit 1
fi