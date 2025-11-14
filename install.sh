#!/bin/bash
# LightRAG Installation Script for RunPod (No Docker)
# RTX Pro 6000 96GB VRAM Setup

set -e

echo "🚀 Installing LightRAG Customer Support System on RunPod..."

# Create working directory
WORK_DIR="/workspace/lightrag-support"
mkdir -p $WORK_DIR
cd $WORK_DIR

echo "📦 Step 1: Installing system dependencies..."
apt-get update
apt-get install -y git curl wget postgresql postgresql-contrib

echo "🐍 Step 2: Setting up Python environment..."
pip install --upgrade pip

echo "📚 Step 3: Installing LightRAG..."
git clone https://github.com/HKUDS/LightRAG.git
cd LightRAG
pip install -e ".[api]"
cd ..

echo "⚡ Step 4: Installing vLLM for Typhoon 2.5..."
# Install compatible vLLM version for your PyTorch/CUDA
pip install vllm==0.5.4 --no-build-isolation
pip install openai  # For OpenAI-compatible API

echo "🧠 Step 5: Installing embedding & reranker dependencies..."
pip install sentence-transformers
pip install FlagEmbedding
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu129

echo "🗄️ Step 6: Installing PostgreSQL Python drivers..."
pip install psycopg2-binary asyncpg pgvector

echo "🌐 Step 7: Installing API server dependencies..."
pip install fastapi uvicorn[standard] pydantic
pip install python-multipart aiofiles

echo "✅ Installation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Start PostgreSQL: sudo service postgresql start"
echo "2. Run setup script: bash setup_postgres.sh"
echo "3. Start services using the launcher: python start_services.py"
echo ""
echo "💡 All services will run in separate screen/tmux sessions"
