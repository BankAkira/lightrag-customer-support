#!/bin/bash
# Check status of all LightRAG services on RunPod

echo "📊 LightRAG Service Status on RunPod"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if any containers are running
if ! docker ps | grep -q lightrag; then
    echo "❌ No LightRAG services are running"
    echo ""
    echo "🚀 To start services: bash deploy-runpod.sh"
    exit 1
fi

# Show container status
echo "🐳 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|lightrag"
echo ""

# Check health of each service
echo "🏥 Health Checks:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# PostgreSQL
if docker exec lightrag-postgres pg_isready -U lightrag > /dev/null 2>&1; then
    echo "✅ PostgreSQL: Ready"
else
    echo "❌ PostgreSQL: Not ready"
fi

# vLLM
if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ vLLM: Ready"
else
    echo "⏳ vLLM: Not ready (may still be loading model)"
fi

# Embedding
if curl -sf http://localhost:8001/health > /dev/null 2>&1; then
    echo "✅ Embedding: Ready"
else
    echo "⏳ Embedding: Not ready"
fi

# Reranker
if curl -sf http://localhost:8002/health > /dev/null 2>&1; then
    echo "✅ Reranker: Ready"
else
    echo "⏳ Reranker: Not ready"
fi

# LightRAG Server
if curl -sf http://localhost:9621/health > /dev/null 2>&1; then
    echo "✅ LightRAG Server: Ready"
else
    echo "⏳ LightRAG Server: Not ready (may be waiting for dependencies)"
fi

echo ""
echo "🖥️  GPU Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits | \
    awk -F', ' '{printf "GPU %s: %s - GPU: %s%% - Memory: %sMB / %sMB\n", $1, $2, $3, $4, $5}'

echo ""
echo "📝 Useful Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "View logs:        docker logs -f lightrag-server"
echo "Stop services:    bash stop-runpod.sh"
echo "Restart:          bash deploy-runpod.sh"
echo "Monitor GPU:      watch -n 1 nvidia-smi"
echo ""
echo "🌐 Access Points:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "LightRAG API:     http://localhost:9621"
echo "API Docs:         http://localhost:9621/docs"
echo "vLLM API:         http://localhost:8000"
echo ""
