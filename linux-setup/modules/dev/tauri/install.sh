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

# Tauri CLI 설치
if ! command -v cargo-tauri &> /dev/null; then
    log_info "📦 Tauri CLI 설치 중 (컴파일에 시간이 다소 소요될 수 있습니다)..."
    # --quiet을 제거하여 진행 상황을 볼 수 있게 하거나, 최소한의 로그 출력
    cargo install tauri-cli
else
    log_info "✅ Tauri CLI가 이미 설치되어 있습니다."
fi

log_success "Tauri 개발 환경 구성 완료"