#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os
echo "Installing SSH Server..."
install_packages openssh-server

# SSH 서비스 이름 결정
SSH_SERVICE="ssh"
if [[ "$OS_ID" == "fedora" ]]; then
    SSH_SERVICE="sshd"
fi

# SSH 설정 파일 백업 및 보안 설정
SSHD_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSHD_CONFIG" ]; then
    sudo cp "$SSHD_CONFIG" "$SSHD_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    
    sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
    sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
    sudo sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSHD_CONFIG"
    sudo sed -i 's/^#*X11Forwarding.*/X11Forwarding yes/' "$SSHD_CONFIG"
    
    if ! grep -q "^Port " "$SSHD_CONFIG"; then
        echo "Port 22" | sudo tee -a "$SSHD_CONFIG" > /dev/null
    fi
    
    sudo systemctl enable "$SSH_SERVICE"
    sudo systemctl restart "$SSH_SERVICE"
fi

# SSH 키 자동 생성 (Ed25519)
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "SSH Ed25519 키 생성 중..."
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$(whoami)@$(hostname)"
    chmod 600 ~/.ssh/id_ed25519
    echo "SSH 키 생성 완료: ~/.ssh/id_ed25519.pub"
fi

# SSH 접속 정보 출력
if systemctl is-active --quiet "$SSH_SERVICE"; then
    echo "✅ SSH 서버 실행 중 ($SSH_SERVICE)"
    echo "📌 SSH 접속 정보:"
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | while read -r ip; do
        echo "   ssh $USER@$ip"
    done
fi

echo "SSH 서버 설정 완료"