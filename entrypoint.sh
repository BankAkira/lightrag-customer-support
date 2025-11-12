#!/bin/bash
set -e
set -u

echo "🚀 Starting LightRAG Server..."

# Maximum wait time in seconds for each service
TIMEOUT=300

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL..."
counter=0
until pg_isready -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER}; do
  counter=$((counter + 2))
  if [ $counter -ge $TIMEOUT ]; then
    echo "❌ PostgreSQL failed to start within ${TIMEOUT} seconds"
    exit 1
  fi
  echo "PostgreSQL is unavailable - sleeping (${counter}s/${TIMEOUT}s)"
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Wait for vLLM to be ready
echo "⏳ Waiting for vLLM..."
counter=0
until curl -f http://vllm:8000/health > /dev/null 2>&1; do
  counter=$((counter + 5))
  if [ $counter -ge $TIMEOUT ]; then
    echo "❌ vLLM failed to start within ${TIMEOUT} seconds"
    exit 1
  fi
  echo "vLLM is unavailable - sleeping (${counter}s/${TIMEOUT}s)"
  sleep 5
done
echo "✅ vLLM is ready!"

# Wait for embedding service to be ready
echo "⏳ Waiting for Embedding service..."
counter=0
until curl -f http://embedding:80/health > /dev/null 2>&1; do
  counter=$((counter + 5))
  if [ $counter -ge $TIMEOUT ]; then
    echo "❌ Embedding service failed to start within ${TIMEOUT} seconds"
    exit 1
  fi
  echo "Embedding service is unavailable - sleeping (${counter}s/${TIMEOUT}s)"
  sleep 5
done
echo "✅ Embedding service is ready!"

# Wait for reranker service to be ready
echo "⏳ Waiting for Reranker service..."
counter=0
until curl -f http://reranker:80/health > /dev/null 2>&1; do
  counter=$((counter + 5))
  if [ $counter -ge $TIMEOUT ]; then
    echo "❌ Reranker service failed to start within ${TIMEOUT} seconds"
    exit 1
  fi
  echo "Reranker service is unavailable - sleeping (${counter}s/${TIMEOUT}s)"
  sleep 5
done
echo "✅ Reranker service is ready!"

echo "🎉 All services are ready! Starting LightRAG Server..."

# Execute the main command
exec "$@"
