#!/bin/bash
set -e
export NVM_DIR="$HOME/.nvm"

if [ -d "$NVM_DIR" ]; then
    echo "NVM 이미 설치됨."
    exit 0
fi

echo "NVM 설치 중..."
# 최신 버전 확인 로직을 간단히 하기 위해 master 브랜치 또는 특정 버전 사용
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

echo "NVM 설치 완료."
