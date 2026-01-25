#!/bin/bash
set -e

if [ -d "$HOME/sts" ] && [ -f "$HOME/sts/SpringToolSuite4" ]; then
    echo "Spring Tool Suite is already installed."
else
    echo "Installing Spring Tool Suite..."
    
    # STS version and download URL (Update as needed)
    STS_VERSION="4.21.1.RELEASE"
    STS_URL="https://download.springsource.com/release/STS4/4.21.1.RELEASE/dist/e4.30/spring-tool-suite-4-4.21.1.RELEASE-e4.30.0-linux.gtk.x86_64.tar.gz"
    
    tmp_base="${TMPDIR:-/tmp}"
    if ! mkdir -p "$tmp_base" 2>/dev/null; then
        tmp_base="$HOME/.cache"
        mkdir -p "$tmp_base"
    fi

    tmpdir="$(mktemp -d -p "$tmp_base" sts.XXXXXX)"
    cleanup() { rm -rf "$tmpdir"; }
    trap cleanup EXIT

    wget -O "$tmpdir/sts.tar.gz" "$STS_URL"

    mkdir -p "$tmpdir/extract"
    # Avoid tar issues on some filesystems
    tar -xzf "$tmpdir/sts.tar.gz" -C "$tmpdir/extract" \
        --touch --no-same-owner --no-same-permissions

    extracted_dir="$(find "$tmpdir/extract" -maxdepth 1 -type d -name 'sts-*' | head -n 1)"
    if [[ -z "$extracted_dir" ]]; then
        echo "❌ Failed to extract STS."
        exit 1
    fi

    rm -rf "$HOME/sts"
    mv "$extracted_dir" "$HOME/sts"
    
    # Create desktop entry directory
    mkdir -p "$HOME/.local/share/applications"
    
    # Create desktop entry
    cat > "$HOME/.local/share/applications/sts.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Spring Tool Suite
Comment=Eclipse-based IDE for Spring development
Exec=$HOME/sts/SpringToolSuite4
Icon=$HOME/sts/icon.xpm
Terminal=false
Categories=Development;IDE;
EOF
    
    chmod +x "$HOME/.local/share/applications/sts.desktop"
    
    echo "Spring Tool Suite installation complete"
    echo "Location: $HOME/sts"
fi