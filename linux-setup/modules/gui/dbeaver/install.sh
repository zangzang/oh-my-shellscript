#!/bin/bash
set -e
if command -v dbeaver &>/dev/null; then
    echo "DBeaver 이미 설치됨."
else
    echo "DBeaver 설치 중..."
    # DBeaver Community Edition
    wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/dbeaver.gpg
    echo "deb [signed-by=/etc/apt/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
    sudo apt update
    sudo apt install -y dbeaver-ce
    echo "DBeaver 설치 완료"
fi
