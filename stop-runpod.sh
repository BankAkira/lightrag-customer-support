#!/bin/bash
# Stop all LightRAG services on RunPod

echo "🛑 Stopping all LightRAG services..."

# Stop all containers
docker stop lightrag-server lightrag-reranker lightrag-embedding lightrag-vllm lightrag-postgres 2>/dev/null || true

# Remove containers
docker rm lightrag-server lightrag-reranker lightrag-embedding lightrag-vllm lightrag-postgres 2>/dev/null || true

echo "✅ All services stopped and removed"
echo ""
echo "💡 Data is preserved in:"
echo "  - Docker volume: postgres_data"
echo "  - Local directories: ./models, ./lightrag_data, ./documents"
echo ""
echo "🔄 To restart: bash deploy-runpod.sh"
echo "🗑️  To remove all data: bash cleanup-runpod.sh"
