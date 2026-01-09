#!/bin/bash
set -e

fix_tmp_dir() {
    if [[ ! -d /tmp ]]; then
        sudo mkdir -p /tmp
    fi

    # /tmp는 일반적으로 1777 (sticky bit 포함) 이어야 함
    local tmp_mode
    tmp_mode=$(stat -c '%a' /tmp 2>/dev/null || echo '')
    if [[ "$tmp_mode" != "1777" ]]; then
        echo "⚠️  /tmp 권한이 비정상입니다 ($tmp_mode). 1777로 복구합니다."
        sudo chmod 1777 /tmp
    fi

    # 실제로 쓰기가 되는지 확인 (apt/gpgv가 내부적으로 임시파일을 쓰는 경우가 있음)
    if ! sudo -u "${SUDO_USER:-$USER}" sh -c 'mktemp -p /tmp >/dev/null' 2>/dev/null; then
        echo "❌ /tmp에 임시 파일을 만들 수 없습니다. /tmp 마운트/권한을 확인하세요."
        exit 1
    fi
}

fix_tmp_dir

# gpgv가 없으면 apt 서명 검증이 실패할 수 있음
if ! command -v gpgv >/dev/null 2>&1; then
    echo "gpgv가 없어 설치를 시도합니다..."
    sudo apt-get install -y --no-install-recommends gpgv || sudo apt-get install -y --no-install-recommends gnupg
fi

sudo apt update
sudo apt upgrade -y
