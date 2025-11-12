#!/bin/bash
# Setup script for RunPod - ensures Docker is installed and running

echo "🔧 RunPod Setup Script"
echo "======================"
echo ""

# Check if running on RunPod
echo "📍 Checking environment..."
if [ -d "/workspace" ]; then
    echo "✅ Detected RunPod environment (/workspace exists)"
else
    echo "⚠️  Warning: Not a typical RunPod environment"
    echo "   (expected /workspace directory)"
fi
echo ""

# Check if Docker is installed
echo "🐳 Checking Docker installation..."
if command -v docker &> /dev/null; then
    echo "✅ Docker is installed"
    docker --version
else
    echo "❌ Docker is not installed"
    echo ""
    read -p "Install Docker now? (y/n): " install_docker
    if [ "$install_docker" = "y" ]; then
        echo "📦 Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        echo "✅ Docker installed"
    else
        echo "❌ Cannot proceed without Docker"
        exit 1
    fi
fi
echo ""

# Check if Docker daemon is running
echo "🔄 Checking Docker daemon..."
if docker ps &> /dev/null 2>&1; then
    echo "✅ Docker daemon is running"
elif sudo docker ps &> /dev/null 2>&1; then
    echo "✅ Docker daemon is running (requires sudo)"
    echo "⚠️  Note: You'll need to use 'sudo' with Docker commands"
else
    echo "⚠️  Docker daemon is not running"
    echo "🔄 Attempting to start Docker..."

    # Try different methods to start Docker based on init system
    DOCKER_STARTED=false

    # Method 1: Direct service command (works on most systems)
    if command -v service &> /dev/null; then
        echo "   Trying: service docker start"
        if sudo service docker start 2>/dev/null; then
            sleep 3
            if docker ps &> /dev/null 2>&1 || sudo docker ps &> /dev/null 2>&1; then
                echo "✅ Started Docker with service command"
                DOCKER_STARTED=true
            fi
        fi
    fi

    # Method 2: Init.d script (fallback)
    if [ "$DOCKER_STARTED" = false ] && [ -f /etc/init.d/docker ]; then
        echo "   Trying: /etc/init.d/docker start"
        if sudo /etc/init.d/docker start 2>/dev/null; then
            sleep 3
            if docker ps &> /dev/null 2>&1 || sudo docker ps &> /dev/null 2>&1; then
                echo "✅ Started Docker with init.d script"
                DOCKER_STARTED=true
            fi
        fi
    fi

    # Method 3: Start dockerd directly (last resort)
    if [ "$DOCKER_STARTED" = false ]; then
        echo "   Trying: dockerd (background)"
        if command -v dockerd &> /dev/null; then
            sudo nohup dockerd > /tmp/dockerd.log 2>&1 &
            sleep 5
            if docker ps &> /dev/null 2>&1 || sudo docker ps &> /dev/null 2>&1; then
                echo "✅ Started dockerd in background"
                DOCKER_STARTED=true
            fi
        fi
    fi

    # Verify Docker is now running
    if [ "$DOCKER_STARTED" = true ]; then
        echo "✅ Docker is now running"
    else
        echo "❌ Could not start Docker automatically"
        echo ""
        echo "Please start Docker manually using one of these methods:"
        echo ""
        echo "Method 1 (recommended):"
        echo "  sudo service docker start"
        echo ""
        echo "Method 2:"
        echo "  sudo /etc/init.d/docker start"
        echo ""
        echo "Method 3:"
        echo "  sudo dockerd &"
        echo ""
        echo "Then verify with:"
        echo "  docker ps"
        echo ""
        exit 1
    fi
fi
echo ""

# Check NVIDIA Docker runtime (for GPU support)
echo "🎮 Checking NVIDIA Docker runtime..."
if docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo "✅ NVIDIA Docker runtime is working"
    echo "✅ GPU is accessible from Docker"
else
    echo "⚠️  NVIDIA Docker runtime check failed"
    echo ""
    echo "This might be okay if:"
    echo "  - You haven't pulled the nvidia/cuda image yet"
    echo "  - GPU drivers are still loading"
    echo ""
    echo "To verify GPU access later, run:"
    echo "  nvidia-smi"
    echo "  docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi"
fi
echo ""

# Check available disk space
echo "💾 Checking disk space..."
available_space=$(df -BG /workspace | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$available_space" -gt 50 ]; then
    echo "✅ Sufficient disk space: ${available_space}GB available"
else
    echo "⚠️  WARNING: Low disk space: ${available_space}GB available"
    echo "   LightRAG needs ~30GB for models + database"
    echo "   Recommended: 50GB+ free space"
fi
echo ""

# Check if in correct directory
echo "📁 Checking current directory..."
if [ -f "deploy-runpod.sh" ]; then
    echo "✅ In correct directory (found deploy-runpod.sh)"
else
    echo "⚠️  deploy-runpod.sh not found in current directory"
    echo "   Make sure you're in the lightrag-support directory"
    if [ -d "/workspace/lightrag-support" ]; then
        echo ""
        echo "Found project at: /workspace/lightrag-support"
        echo "Run: cd /workspace/lightrag-support"
    fi
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Configure .env file:"
echo "   cp .env.example .env"
echo "   nano .env  # Change POSTGRES_PASSWORD"
echo ""
echo "2. Validate configuration:"
echo "   bash validate-env.sh"
echo ""
echo "3. Deploy LightRAG:"
echo "   bash deploy-runpod.sh"
echo ""
echo "4. Check status:"
echo "   bash status-runpod.sh"
echo ""
