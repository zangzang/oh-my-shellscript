#!/bin/bash
set -e

# 라이브러리 로드
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

echo "📦 시스템 패키지로 Rust 설치 시도..."

PKGS=()
if [[ "$OS_ID" == "fedora" ]]; then
    PKGS=("rust" "cargo")
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    PKGS=("rustc" "cargo")
else
    PKGS=("rustc" "cargo") # Default try
fi

INSTALLED_NATIVE=false
if install_packages "${PKGS[@]}"; then
    echo "✅ Rust 시스템 패키지 설치 완료"
    INSTALLED_NATIVE=true
else
    echo "⚠️  시스템 패키지 설치 실패. Fallback 모드로 전환합니다."
fi

if [[ "$INSTALLED_NATIVE" == "true" ]]; then
    exit 0
fi

# Fallback: Rustup
echo "🔄 Rustup을 통한 설치 시도..."
export CARGO_HOME="$HOME/.cargo"

if command -v cargo &>/dev/null; then
    echo "Rust가 이미 설치되어 있습니다."
    exit 0
fi

if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
    echo "Rust 설치 완료 (Rustup)"
else
    echo "❌ Rust 설치 실패"
    exit 1
fi