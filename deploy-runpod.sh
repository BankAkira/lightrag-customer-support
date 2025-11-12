#!/bin/bash
# Deploy LightRAG Customer Support on RunPod WITHOUT docker-compose
# This script uses plain docker commands

set -e

echo "🚀 Deploying LightRAG Customer Support on RunPod..."

# Check if Docker is installed and running
echo "🔍 Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "❌ ERROR: Docker is not installed or not in PATH"
    echo ""
    echo "On RunPod, Docker should be pre-installed. Possible issues:"
    echo ""
    echo "1. Docker service is not started:"
    echo "   sudo service docker start"
    echo "   # or"
    echo "   sudo systemctl start docker"
    echo ""
    echo "2. Docker not in PATH. Try:"
    echo "   which docker"
    echo "   export PATH=\$PATH:/usr/bin"
    echo ""
    echo "3. Need to install Docker (if really missing):"
    echo "   curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "   sudo sh get-docker.sh"
    echo ""
    exit 1
fi

# Check if Docker daemon is running
if ! docker ps &> /dev/null; then
    echo "❌ ERROR: Docker daemon is not running"
    echo ""
    echo "Start Docker with:"
    echo "  sudo service docker start"
    echo "  # or"
    echo "  sudo systemctl start docker"
    echo ""
    echo "Check Docker status:"
    echo "  sudo service docker status"
    echo ""
    exit 1
fi

echo "✅ Docker is installed and running"
docker --version

# Load environment variables from .env file
if [ -f .env ]; then
    echo "📋 Loading environment variables from .env..."
    # Use set -a to automatically export variables, then source the file
    set -a
    source <(grep -v '^#' .env | grep -v '^$')
    set +a
else
    echo "⚠️  .env file not found. Using defaults..."
fi

# Set defaults for critical variables
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-CHANGE_ME_BEFORE_PRODUCTION}
export POSTGRES_USER=${POSTGRES_USER:-lightrag}
export POSTGRES_DATABASE=${POSTGRES_DATABASE:-lightrag}
export ENTITY_TYPES=${ENTITY_TYPES:-'["organization", "person", "product", "service", "location", "event", "issue", "feature"]'}

# Verify critical configuration
echo "✅ Configuration loaded:"
echo "   Database: ${POSTGRES_DATABASE}"
echo "   User: ${POSTGRES_USER}"
echo "   Password: ${POSTGRES_PASSWORD:0:3}*** (hidden)"
echo ""

# Create Docker network
echo "🌐 Creating Docker network..."
docker network create lightrag-network 2>/dev/null || echo "Network already exists"

# Create required directories
echo "📁 Creating data directories..."
mkdir -p models/embeddings models/reranker lightrag_data documents

# Create volume for PostgreSQL
echo "💾 Creating PostgreSQL volume..."
docker volume create postgres_data 2>/dev/null || echo "Volume already exists"

# Stop and remove existing containers (if any)
echo "🧹 Cleaning up existing containers..."
docker rm -f lightrag-postgres lightrag-vllm lightrag-embedding lightrag-reranker lightrag-server 2>/dev/null || true

# 1. Start PostgreSQL with pgvector
echo "1️⃣  Starting PostgreSQL with pgvector..."
docker run -d \
    --name lightrag-postgres \
    --network lightrag-network \
    -p 5432:5432 \
    -e POSTGRES_DB=${POSTGRES_DATABASE} \
    -e POSTGRES_USER=${POSTGRES_USER} \
    -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    -v postgres_data:/var/lib/postgresql/data \
    --restart unless-stopped \
    --health-cmd "pg_isready -U ${POSTGRES_USER}" \
    --health-interval 10s \
    --health-timeout 5s \
    --health-retries 5 \
    pgvector/pgvector:pg16

echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 10

# 2. Start vLLM service (Typhoon 2.5)
echo "2️⃣  Starting vLLM (Typhoon 2.5) - This will use GPU..."
docker run -d \
    --name lightrag-vllm \
    --network lightrag-network \
    --gpus all \
    -p 8000:8000 \
    -e CUDA_VISIBLE_DEVICES=0 \
    -v $(pwd)/models:/root/.cache/huggingface \
    --shm-size 4g \
    --restart unless-stopped \
    --health-cmd "curl -f http://localhost:8000/health" \
    --health-interval 30s \
    --health-timeout 10s \
    --health-retries 3 \
    vllm/vllm-openai:latest \
    --model scb10x/typhoon-v2.5-instruct \
    --host 0.0.0.0 \
    --port 8000 \
    --tensor-parallel-size 1 \
    --gpu-memory-utilization 0.4 \
    --max-model-len 32768 \
    --dtype auto

echo "⏳ Waiting for vLLM to download model (this may take 5-10 minutes on first run)..."
sleep 30

# 3. Start BGE-M3 Embedding service
echo "3️⃣  Starting BGE-M3 Embedding service..."
docker run -d \
    --name lightrag-embedding \
    --network lightrag-network \
    --gpus all \
    -p 8001:80 \
    -e MODEL_ID=BAAI/bge-m3 \
    -e CUDA_VISIBLE_DEVICES=0 \
    -e MAX_BATCH_TOKENS=16384 \
    -v $(pwd)/models/embeddings:/data \
    --restart unless-stopped \
    --health-cmd "curl -f http://localhost:80/health" \
    --health-interval 30s \
    --health-timeout 10s \
    --health-retries 3 \
    ghcr.io/huggingface/text-embeddings-inference:1.5

echo "⏳ Waiting for Embedding service..."
sleep 20

# 4. Start BGE Reranker service
echo "4️⃣  Starting BGE Reranker service..."
docker run -d \
    --name lightrag-reranker \
    --network lightrag-network \
    --gpus all \
    -p 8002:80 \
    -e MODEL_ID=BAAI/bge-reranker-v2-m3 \
    -e CUDA_VISIBLE_DEVICES=0 \
    -v $(pwd)/models/reranker:/data \
    --restart unless-stopped \
    --health-cmd "curl -f http://localhost:80/health" \
    --health-interval 30s \
    --health-timeout 10s \
    --health-retries 3 \
    ghcr.io/huggingface/text-embeddings-inference:1.5

echo "⏳ Waiting for Reranker service..."
sleep 20

# 5. Start LightRAG Server
echo "5️⃣  Starting LightRAG Server..."
docker run -d \
    --name lightrag-server \
    --network lightrag-network \
    -p 9621:9621 \
    -e LLM_MODEL_NAME=scb10x/typhoon-v2.5-instruct \
    -e LLM_BASE_URL=http://lightrag-vllm:8000/v1 \
    -e LLM_API_KEY=dummy \
    -e LLM_MAX_TOKENS=32768 \
    -e LLM_TEMPERATURE=0.7 \
    -e EMBEDDING_MODEL=BAAI/bge-m3 \
    -e EMBEDDING_BASE_URL=http://lightrag-embedding:80 \
    -e EMBEDDING_DIM=1024 \
    -e RERANKER_MODEL=BAAI/bge-reranker-v2-m3 \
    -e RERANKER_BASE_URL=http://lightrag-reranker:80 \
    -e KV_STORAGE=PGKVStorage \
    -e VECTOR_STORAGE=PGVectorStorage \
    -e GRAPH_STORAGE=PGGraphStorage \
    -e DOC_STATUS_STORAGE=PGDocStatusStorage \
    -e POSTGRES_HOST=lightrag-postgres \
    -e POSTGRES_PORT=5432 \
    -e POSTGRES_USER=${POSTGRES_USER} \
    -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    -e POSTGRES_DATABASE=${POSTGRES_DATABASE} \
    -e WORKING_DIR=/app/lightrag_data \
    -e WORKSPACE=customer_support \
    -e CHUNK_TOKEN_SIZE=1200 \
    -e CHUNK_OVERLAP_TOKEN_SIZE=100 \
    -e MAX_ASYNC=4 \
    -e MAX_EMBED_TOKENS=8192 \
    -e TOP_K=60 \
    -e CHUNK_TOP_K=20 \
    -e LANGUAGE="${LANGUAGE:-Thai and English}" \
    -e ENTITY_TYPES="${ENTITY_TYPES}" \
    -v $(pwd)/lightrag_data:/app/lightrag_data \
    -v $(pwd)/documents:/app/documents \
    --restart unless-stopped \
    --health-cmd "curl -f http://localhost:9621/health" \
    --health-interval 30s \
    --health-timeout 10s \
    --health-retries 5 \
    --health-start-period 60s \
    ghcr.io/hkuds/lightrag:latest

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Service Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep lightrag || true
echo ""
echo "🔍 Check logs with:"
echo "  docker logs -f lightrag-server"
echo "  docker logs -f lightrag-vllm"
echo "  docker logs -f lightrag-embedding"
echo ""
echo "🌐 Access points:"
echo "  LightRAG API: http://localhost:9621"
echo "  vLLM API: http://localhost:8000"
echo "  Embedding API: http://localhost:8001"
echo ""
echo "💡 To stop all services:"
echo "  bash stop-runpod.sh"
echo ""
