#!/bin/bash
# Manual Docker start script for RunPod (when setup-runpod.sh fails)

echo "🐳 Starting Docker on RunPod..."
echo ""

# Check if already running
if docker ps &> /dev/null 2>&1; then
    echo "✅ Docker is already running!"
    docker --version
    exit 0
elif sudo docker ps &> /dev/null 2>&1; then
    echo "✅ Docker is already running (with sudo)!"
    sudo docker --version
    echo ""
    echo "⚠️  Note: You'll need to run deploy script with sudo:"
    echo "   sudo bash deploy-runpod.sh"
    exit 0
fi

echo "Attempting to start Docker..."
echo ""

# Method 1: service command
echo "Method 1: Using service command..."
sudo service docker start
sleep 3

if docker ps &> /dev/null 2>&1 || sudo docker ps &> /dev/null 2>&1; then
    echo "✅ Docker started successfully!"
    docker ps || sudo docker ps
    exit 0
fi

# Method 2: init.d script
echo "Method 2: Using init.d script..."
sudo /etc/init.d/docker start 2>/dev/null
sleep 3

if docker ps &> /dev/null 2>&1 || sudo docker ps &> /dev/null 2>&1; then
    echo "✅ Docker started successfully!"
    docker ps || sudo docker ps
    exit 0
fi

# Method 3: dockerd directly
echo "Method 3: Starting dockerd directly..."
if command -v dockerd &> /dev/null; then
    echo "Starting dockerd in background..."
    sudo nohup dockerd > /tmp/dockerd.log 2>&1 &
    echo "Waiting for Docker to initialize (10 seconds)..."
    sleep 10

    if docker ps &> /dev/null 2>&1 || sudo docker ps &> /dev/null 2>&1; then
        echo "✅ Docker started successfully!"
        docker ps || sudo docker ps
        echo ""
        echo "Docker logs: /tmp/dockerd.log"
        exit 0
    fi
fi

# All methods failed
echo "❌ Failed to start Docker"
echo ""
echo "Troubleshooting steps:"
echo ""
echo "1. Check if Docker is installed:"
echo "   which docker"
echo "   docker --version"
echo ""
echo "2. Check Docker logs:"
echo "   cat /tmp/dockerd.log"
echo "   sudo journalctl -u docker"
echo ""
echo "3. Try starting manually:"
echo "   sudo dockerd"
echo "   (Press Ctrl+C to stop, then run in background with: sudo dockerd &)"
echo ""
echo "4. Check for errors:"
echo "   sudo dockerd --debug"
echo ""
echo "5. On RunPod, you can also:"
echo "   - Restart your pod from the RunPod dashboard"
echo "   - Choose a different RunPod template with Docker pre-configured"
echo ""

exit 1
