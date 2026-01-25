#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os
echo "Installing SSH Server..."
install_packages openssh-server

# Determine SSH service name
SSH_SERVICE="ssh"
if [[ "$OS_ID" == "fedora" ]]; then
    SSH_SERVICE="sshd"
fi

# Backup SSH configuration and apply security settings
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

# Auto-generate SSH key (Ed25519)
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating SSH Ed25519 key..."
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$(whoami)@$(hostname)"
    chmod 600 ~/.ssh/id_ed25519
    echo "SSH key generation complete: ~/.ssh/id_ed25519.pub"
fi

# Display SSH connection info
if systemctl is-active --quiet "$SSH_SERVICE"; then
    echo "✅ SSH Server is running ($SSH_SERVICE)"
    echo "📌 SSH Connection Info:"
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | while read -r ip; do
        echo "   ssh $USER@$ip"
    done
fi

echo "SSH Server setup complete"
