#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/core.sh"

log_info "Tauri 필수 시스템 패키지 설치 중..."

detect_os

# Tauri 의존성 패키지 (https://tauri.app/start/prerequisites/#linux)
PACKAGES=(
  "libgtk-3-dev"           
  "libglib2.0-dev"         
  "libwebkit2gtk-4.1-dev"  
  "librsvg2-dev"           
  "libssl-dev"             
  "pkg-config"             
  "libjavascriptcoregtk-4.1-dev"
  "libsoup2.4-dev"
)

install_packages "${PACKAGES[@]}"

# Rust 환경 로드
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

if ! command -v cargo &> /dev/null; then
    # PATH에 없을 경우를 대비해 수동으로 추가 시도
    export PATH="$HOME/.cargo/bin:$PATH"
fi

if ! command -v cargo &> /dev/null; then
    log_error "Cargo(Rust)를 찾을 수 없습니다. dev.rust 모듈이 설치되었는지 확인하세요."
    exit 1
fi

# Tauri CLI 설치
if ! command -v cargo-tauri &> /dev/null; then
    log_info "📦 Tauri CLI 설치 중 (컴파일에 시간이 다소 소요될 수 있습니다)..."
    cargo install tauri-cli
else
    log_info "✅ Tauri CLI가 이미 설치되어 있습니다."
fi

log_success "Tauri 개발 환경 구성 완료"