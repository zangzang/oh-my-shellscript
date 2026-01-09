#!/bin/bash
set -e
echo "Installing CLI tools..."
sudo apt install -y \
    jq tree htop btop ncdu mc \
    bat ripgrep fd-find eza fzf \
    vim nano
