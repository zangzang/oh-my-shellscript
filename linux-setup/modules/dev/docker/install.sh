#!/bin/bash
set -e

# Load Library
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

if [ -z "${OS_ID:-}" ]; then
    detect_os
fi

if command -v docker &>/dev/null; then
    ui_log_info "Docker is already installed."
    # Ensure user is in group (only if docker group exists - not in WSL with Docker Desktop)
    if getent group docker &>/dev/null; then
        if ! groups $USER | grep -q "\bdocker\b"; then
            ui_log_info "Adding $USER to docker group..."
            sudo usermod -aG docker $USER
        fi
    else
        ui_log_info "Docker group does not exist (possibly using Docker Desktop in WSL)"
    fi
    ui_log_success "Docker is ready."
    exit 0
fi

ui_log_info "Installing Docker Engine..."

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS_ID/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --batch --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS_ID \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

elif [[ "$OS_ID" == "fedora" ]]; then
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
else
    ui_log_error "Unsupported OS for Docker automatic installation: $OS_ID"
    exit 1
fi

# Ensure Docker service is started and enabled
ui_log_info "Starting Docker service..."
sudo systemctl enable --now docker

# Wait for Docker daemon to be ready
ui_log_info "Waiting for Docker daemon to be ready..."
attempt=0
while ! sudo docker ps &>/dev/null; do
    ((attempt++))
    if [ $attempt -gt 12 ]; then
        ui_log_error "Docker daemon failed to start or is not responding."
        exit 1
    fi
    echo -n "."
    sleep 2
done
echo ""

# Add current user to docker group (if group exists)
if getent group docker &>/dev/null; then
    ui_log_info "Adding $USER to docker group..."
    sudo usermod -aG docker $USER
fi

ui_log_success "Docker installation complete and daemon is ready."