#!/bin/bash
set -e

# Load Library
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

echo "📱 Setting up Android development environment and emulator..."

# 1. Install virtualization and essential dependencies (KVM, etc.)
echo "📦 Installing virtualization system packages..."
KVM_PKGS=()
if [[ "$OS_ID" == "fedora" ]]; then
    KVM_PKGS=("qemu-kvm" "bridge-utils" "libvirt" "virt-install" "unzip")
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    KVM_PKGS=("qemu-kvm" "libvirt-daemon-system" "libvirt-clients" "bridge-utils" "unzip" "libc6" "libstdc++6" "libbz2-1.0" "libncurses5")
fi

install_packages "${KVM_PKGS[@]}"

# Add current user to kvm/libvirt groups
if getent group kvm >/dev/null; then
    sudo usermod -aG kvm "$USER" || true
fi
if getent group libvirt >/dev/null; then
    sudo usermod -aG libvirt "$USER" || true
fi

# 2. Setup Android SDK directory
export ANDROID_HOME="$HOME/Android/Sdk"
CMDLINE_TOOLS_ROOT="$ANDROID_HOME/cmdline-tools"
mkdir -p "$CMDLINE_TOOLS_ROOT"

# 3. Download Command Line Tools (if not already installed)
if [[ ! -d "$CMDLINE_TOOLS_ROOT/latest" ]]; then
    echo "📥 Downloading Android Command Line Tools..."
    # Latest version as of late 2024 (commandlinetools-linux-11076708_latest.zip)
    CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    TEMP_ZIP="/tmp/cmdline-tools.zip"
    
    curl -o "$TEMP_ZIP" "$CMDLINE_URL"
    unzip -q "$TEMP_ZIP" -d "$CMDLINE_TOOLS_ROOT"
    
    # Rearrange directory structure (sdkmanager expects cmdline-tools/latest/bin/sdkmanager)
    mv "$CMDLINE_TOOLS_ROOT/cmdline-tools" "$CMDLINE_TOOLS_ROOT/latest"
    rm "$TEMP_ZIP"
    echo "✅ Command Line Tools installed"
else
    echo "✅ Command Line Tools already exist"
fi

# Temporarily set environment variables (for script execution)
export PATH="$CMDLINE_TOOLS_ROOT/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# Check Java (Depends on dev.java but env might be missing)
if ! command -v java &>/dev/null; then
    # Try loading SDKMAN
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

if ! command -v java &>/dev/null; then
    echo "❌ Java not found. Please ensure 'dev.java' module is installed."
    exit 1
fi

# 4. Accept Licenses
echo "📜 Accepting Android SDK licenses..."
yes | sdkmanager --licenses >/dev/null 2>&1 || true

# 5. Install essential SDK packages and System Image
# Target API Level 35 (Android 15)
target_api="35"
build_tools_ver="35.0.0"
sys_img="system-images;android-${target_api};google_apis;x86_64"

echo "📥 Downloading SDK packages and Emulator image (This may take a while)..."
echo "   Target: platform-tools, platforms;android-${target_api}, build-tools;${build_tools_ver}, emulator, $sys_img"



sdkmanager "platform-tools" \
           "platforms;android-${target_api}" \
           "build-tools;${build_tools_ver}" \
           "emulator" \
           "$sys_img"

# 6. Create AVD (Emulator)
AVD_NAME="pixel_default"
if ! avdmanager list avd | grep -q "$AVD_NAME"; then
    echo "📱 Creating default AVD ($AVD_NAME)..."
    # 'no' answers the custom hardware profile question
    echo "no" | avdmanager create avd -n "$AVD_NAME" -k "$sys_img" --device "pixel" --force
    echo "✅ AVD created: $AVD_NAME"
else
    echo "✅ AVD already exists: $AVD_NAME"
fi

echo "🎉 Android development environment setup complete."
echo "   Re-login might be required for KVM group changes to take effect."