#!/bin/bash
set -e

# 라이브러리 로드
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

echo "🟢 NVIDIA GPU 환경 설정 중..."

# 1. 드라이버 체크
if ! command -v nvidia-smi &>/dev/null; then
    echo "⚠️  NVIDIA 드라이버가 감지되지 않았습니다."
    echo "   설치를 원하시면 다음 명령어를 별도로 실행하세요:"
    if [[ "$OS_ID" == "fedora" ]]; then
        echo "   sudo dnf install akmod-nvidia"
    else
        echo "   sudo ubuntu-drivers autoinstall"
    fi
    echo "------------------------------------------"
fi

# 2. NVIDIA Container Toolkit 설치 (Docker용)
echo "📦 NVIDIA Container Toolkit 설치 중..."
if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt update && sudo apt install -y nvidia-container-toolkit
elif [[ "$OS_ID" == "fedora" ]]; then
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
        sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
    sudo dnf install -y nvidia-container-toolkit
fi

# 3. Docker 재시작
echo "🔄 GPU 지원을 위해 Docker를 재시작합니다..."
sudo systemctl restart docker

echo "✅ NVIDIA 환경 설정 완료"
