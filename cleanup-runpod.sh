#!/bin/bash
# Clean up all LightRAG data on RunPod (WARNING: This deletes everything!)

echo "⚠️  WARNING: This will delete ALL data including:"
echo "  - All containers"
echo "  - PostgreSQL database"
echo "  - Downloaded models (~23GB)"
echo "  - Indexed documents"
echo "  - Knowledge graphs"
echo ""
read -p "Are you sure? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo "🗑️  Cleaning up..."

# Stop and remove containers
bash stop-runpod.sh 2>/dev/null || true

# Remove Docker network
echo "Removing Docker network..."
docker network rm lightrag-network 2>/dev/null || true

# Remove Docker volume
echo "Removing PostgreSQL volume..."
docker volume rm postgres_data 2>/dev/null || true

# Remove local directories
echo "Removing local data directories..."
rm -rf models/ lightrag_data/ documents/

echo "✅ Cleanup complete!"
echo "🔄 To redeploy: bash deploy-runpod.sh"
