#!/bin/bash
set -e

# Install Gemini CLI globally
if ! command -v gemini &> /dev/null; then
    echo "Installing Gemini CLI..."
    npm install -g @google/gemini-cli
else
    echo "Gemini CLI is already installed."
fi
