#!/bin/bash
set -e

echo "🚀 Starting LightRAG Server..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL..."
until pg_isready -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER}; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Wait for vLLM to be ready
echo "⏳ Waiting for vLLM..."
until curl -f http://vllm:8000/health > /dev/null 2>&1; do
  echo "vLLM is unavailable - sleeping"
  sleep 5
done
echo "✅ vLLM is ready!"

# Wait for embedding service to be ready
echo "⏳ Waiting for Embedding service..."
until curl -f http://embedding:80/health > /dev/null 2>&1; do
  echo "Embedding service is unavailable - sleeping"
  sleep 5
done
echo "✅ Embedding service is ready!"

echo "🎉 All services are ready! Starting LightRAG Server..."

# Execute the main command
exec "$@"
