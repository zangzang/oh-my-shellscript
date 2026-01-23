#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

echo "🦙 Ollama 설치 중..."

# 필수 패키지 설치 (awk, curl, zstd)
echo "📦 필수 의존성 확인 중..."
install_packages curl gawk zstd

if command -v ollama &>/dev/null; then
    echo "✅ Ollama가 이미 설치되어 있습니다."
else
    # 공식 설치 스크립트 실행
    curl -fsSL https://ollama.com/install.sh | sh
fi

# 서비스 상태 확인
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama 서비스가 실행 중입니다."
else
    echo "⚙️  Ollama 서비스를 시작합니다..."
    sudo systemctl enable --now ollama || true
fi

echo "🎉 Ollama 엔진 설치 완료"
