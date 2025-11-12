#!/bin/bash
# Install Docker Compose on RunPod
# Run this once: bash install-docker-compose.sh

set -e

echo "🚀 Installing Docker Compose on RunPod..."

# Check if docker-compose already exists
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose is already installed!"
    docker-compose --version
    exit 0
fi

# Install Docker Compose v2 (standalone binary)
COMPOSE_VERSION="v2.24.1"
echo "📦 Downloading Docker Compose ${COMPOSE_VERSION}..."

# Create bin directory if it doesn't exist
mkdir -p ~/.local/bin

# Download Docker Compose
curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
    -o ~/.local/bin/docker-compose

# Make it executable
chmod +x ~/.local/bin/docker-compose

# Add to PATH if not already there
if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" ~/.bashrc; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
    echo "✅ Added ~/.local/bin to PATH in ~/.bashrc"
fi

# Source bashrc or use direct path
export PATH=$HOME/.local/bin:$PATH

# Verify installation
if ~/.local/bin/docker-compose --version; then
    echo "✅ Docker Compose installed successfully!"
    echo "Run: source ~/.bashrc (or restart your shell)"
    echo "Then: docker-compose up -d"
else
    echo "❌ Installation failed"
    exit 1
fi
