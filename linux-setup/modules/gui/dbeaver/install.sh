#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

if command -v dbeaver &>/dev/null; then
    ui_log_info "DBeaver is already installed."
    exit 0
fi

ui_log_info "Installing DBeaver Universal Database Tool..."

if [ "$OS_ID" == "fedora" ]; then
    if command -v rpm &>/dev/null; then
        sudo rpm --import https://dbeaver.io/debs/dbeaver.gpg.key
    fi
    if [ ! -f /etc/yum.repos.d/dbeaver.repo ]; then
        echo -e "[dbeaver]\nname=DBeaver Corp\nbaseurl=https://dbeaver.io/rpm/\nenabled=1\ngpgcheck=1\ngpgkey=https://dbeaver.io/debs/dbeaver.gpg.key" | sudo tee /etc/yum.repos.d/dbeaver.repo > /dev/null
    fi
    sudo dnf install -y dbeaver-ce
else
    # DBeaver Community Edition (Ubuntu/Debian)
    sudo mkdir -p /etc/apt/keyrings
    wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/dbeaver.gpg --batch --yes
    echo "deb [signed-by=/etc/apt/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
    sudo apt update
    sudo apt install -y dbeaver-ce
fi
ui_log_success "DBeaver installation complete"
