#!/bin/bash
set -e

if command -v docker &>/dev/null; then
    echo "✅ Docker is already installed."
    # Ensure user is in group even if already installed
    if ! groups $USER | grep &>/dev/null "\bdocker\b"; then
        echo "Adding $USER to docker group..."
        sudo usermod -aG docker $USER
    fi
    exit 0
fi

echo "📦 Installing Docker..."

# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --batch --yes
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

# Install Docker Engine
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
echo "Adding $USER to docker group..."
sudo usermod -aG docker $USER

echo "✅ Docker installation complete."
echo "⚠️  NOTE: You may need to log out and back in for group changes to take effect."
echo "          Alternatively, run 'newgrp docker' in your current terminal."

