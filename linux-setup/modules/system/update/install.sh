#!/bin/bash
set -e

# 라이브러리 로드
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

fix_tmp_dir() {
    if [[ ! -d /tmp ]]; then
        sudo mkdir -p /tmp
    fi
    local tmp_mode
    tmp_mode=$(stat -c '%a' /tmp 2>/dev/null || echo '')
    if [[ "$tmp_mode" != "1777" ]]; then
        echo "⚠️  /tmp 권한이 비정상입니다 ($tmp_mode). 1777로 복구합니다."
        sudo chmod 1777 /tmp
    fi
    if ! sudo -u "${SUDO_USER:-$USER}" sh -c 'mktemp -p /tmp >/dev/null' 2>/dev/null; then
        echo "❌ /tmp에 임시 파일을 만들 수 없습니다. /tmp 마운트/권한을 확인하세요."
        exit 1
    fi
}

fix_tmp_dir

echo "🔄 시스템 업데이트 실행 중..."

if [[ "$OS_ID" == "fedora" ]]; then
    # DNF 최적화 (속도 향상)
    if ! grep -q "fastestmirror=True" /etc/dnf/dnf.conf 2>/dev/null; then
        echo "⚡ DNF 속도 최적화 적용 (fastestmirror, max_parallel_downloads)..."
        echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
        echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    fi
    sudo dnf update -y
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    # Ubuntu/Debian
    # gpgv 확인
    if ! command -v gpgv >/dev/null 2>&1; then
        echo "gpgv 설치 중..."
        sudo apt-get install -y --no-install-recommends gpgv || sudo apt-get install -y --no-install-recommends gnupg
    fi
    sudo apt update
    sudo apt upgrade -y
else
    echo "⚠️  자동 업데이트를 지원하지 않는 OS입니다: $OS_ID"
fi