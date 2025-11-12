# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a LightRAG-based customer support system optimized for RunPod RTX Pro 6000 (96GB VRAM). The system provides multilingual (Thai + English) AI-powered customer support using knowledge graph and vector retrieval.

## Architecture

The system consists of 5 Docker services that work together:

1. **vLLM Service** (port 8000): Runs Typhoon 2.5 LLM for text generation using GPU acceleration
2. **BGE-M3 Embedding** (port 8001): Multilingual text embeddings (1024 dimensions) using GPU
3. **BGE Reranker** (port 8002): Result reranking for better retrieval quality using GPU
4. **PostgreSQL + pgvector** (port 5432): Persistent storage for documents, vectors, knowledge graph, and processing status
5. **LightRAG Server** (port 9621): Main API server (official image: ghcr.io/hkuds/lightrag:latest) that orchestrates all services

### Storage Architecture

LightRAG uses PostgreSQL for all storage layers:
- `PGKVStorage`: Document and chunk key-value storage
- `PGVectorStorage`: Vector embeddings with pgvector extension
- `PGGraphStorage`: Knowledge graph (entities and relationships)
- `PGDocStatusStorage`: Document processing status tracking

### GPU Memory Allocation

On RTX Pro 6000 (96GB VRAM), the default allocation is:
- vLLM (Typhoon 2.5): ~40GB (controlled by `--gpu-memory-utilization 0.4`)
- BGE-M3 Embedding: ~4GB
- BGE Reranker: ~2GB
- Remaining: ~50GB buffer for scaling

## Common Commands

### Deployment Options

**Option 1: RunPod (No docker-compose)** - Recommended for RunPod environments

```bash
# Deploy all services with plain Docker commands
bash deploy-runpod.sh

# Check status
bash status-runpod.sh

# View logs
docker logs -f lightrag-server
docker logs -f lightrag-vllm

# Stop all services
bash stop-runpod.sh

# Clean up everything (WARNING: deletes data)
bash cleanup-runpod.sh
```

**Option 2: Docker Compose** - Traditional deployment

```bash
# Install docker-compose if needed
bash install-docker-compose.sh

# Start all services
docker-compose up -d

# View logs (all services)
docker-compose logs -f

# View logs for specific service
docker-compose logs -f vllm          # LLM inference logs
docker-compose logs -f embedding     # Embedding service logs
docker-compose logs -f lightrag      # Main server logs
docker-compose logs -f postgres      # Database logs

# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v

# Pull latest LightRAG image
docker-compose pull lightrag

# Restart services
docker-compose up -d

# Check service health
docker-compose ps
curl http://localhost:9621/health    # Main server
curl http://localhost:8000/health    # vLLM
curl http://localhost:8001/health    # Embedding
```

### GPU Monitoring

```bash
# Monitor GPU usage in real-time
watch -n 1 nvidia-smi

# Check GPU memory usage by container
docker stats

# Verify GPU is accessible from Docker
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

### Database Operations

```bash
# Connect to PostgreSQL
docker exec -it lightrag-postgres psql -U lightrag -d lightrag

# Common SQL queries
# List all tables: \dt
# Show vector table: SELECT * FROM vectors LIMIT 5;
# Show entities: SELECT * FROM entities LIMIT 10;
# Show document status: SELECT * FROM doc_status;
# Exit: \q

# Backup database
docker exec lightrag-postgres pg_dump -U lightrag lightrag > backup.sql

# Restore database
cat backup.sql | docker exec -i lightrag-postgres psql -U lightrag lightrag
```

### Testing & API Usage

```bash
# Run the example client (indexes documents and queries)
python api_client_example.py

# Health check with curl
curl http://localhost:9621/health

# Index a document
curl -X POST http://localhost:9621/v1/documents/index \
  -H "Content-Type: application/json" \
  -d '{"documents": ["Your document text"], "doc_ids": ["doc-001"]}'

# Query the system (Thai or English)
curl -X POST http://localhost:9621/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Your question", "mode": "hybrid", "enable_rerank": true}'

# Access API documentation
# Navigate to http://localhost:9621/docs
```

## Configuration

### Key Environment Variables (.env)

**GPU/Performance Tuning:**
- `LLM_MAX_TOKENS`: Context length (default: 32768)
- Adjust vLLM `--gpu-memory-utilization` in docker-compose.yml (0.3-0.7)
- `MAX_ASYNC`: Concurrent operations (default: 4, increase for higher throughput)
- `CHUNK_TOKEN_SIZE`: Chunk size for documents (default: 1200)

**Language & Entity Configuration:**
- `LANGUAGE`: "Thai and English" (modify for other languages)
- `ENTITY_TYPES`: JSON array of entity types to extract (organization, person, product, service, etc.)

**Retrieval Settings:**
- `TOP_K`: Number of entities to retrieve (default: 60)
- `CHUNK_TOP_K`: Number of chunks to retrieve (default: 20)
- `ENABLE_RERANK`: Use reranker for better results (default: true)

**PostgreSQL:**
- `POSTGRES_PASSWORD`: Change from default "lightrag_password_change_me" before production
- `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_DATABASE`

### Query Modes

LightRAG supports different retrieval strategies:
- `hybrid`: Combines local + global search (recommended for most cases)
- `mix`: Knowledge graph + vector search (best with reranker enabled)
- `local`: Context-dependent, entity-focused information
- `global`: High-level summary from global knowledge
- `naive`: Simple vector similarity search

## File Structure

```
.
├── docker-compose.yml          # Service orchestration (optional, uses official images)
├── Dockerfile.custom           # OPTIONAL: For customizing LightRAG image
├── .env                       # Configuration (CHANGE PASSWORDS!)
├── .env.example               # Template for environment variables
├── api_client_example.py      # Python API client with examples
│
├── RUNPOD_GUIDE.md            # RunPod deployment guide (no docker-compose)
├── DEPLOYMENT_GUIDE.md        # Deployment guide (with docker-compose)
├── README.md                  # Project overview
├── CLAUDE.md                  # This file
│
├── deploy-runpod.sh           # Deploy on RunPod (plain Docker, no compose)
├── stop-runpod.sh             # Stop all RunPod services
├── status-runpod.sh           # Check RunPod service status
├── cleanup-runpod.sh          # Clean up all RunPod data
├── install-docker-compose.sh  # Install docker-compose if needed
├── entrypoint.sh              # OPTIONAL: Custom startup script (reference)
│
├── lightrag_data/             # Working directory (created at runtime)
├── documents/                 # Document storage (created at runtime)
└── models/                    # Model cache (created at runtime)
```

## Customizing LightRAG (Advanced)

By default, the system uses the official LightRAG image: `ghcr.io/hkuds/lightrag:latest`

If you need to customize the LightRAG installation:

1. Edit `Dockerfile.custom` to add your customizations
2. Update `docker-compose.yml` lightrag service:
   ```yaml
   lightrag:
     build:
       context: .
       dockerfile: Dockerfile.custom
     # Comment out: image: ghcr.io/hkuds/lightrag:latest
   ```
3. Build and deploy:
   ```bash
   docker-compose build lightrag
   docker-compose up -d lightrag
   ```

Common customization scenarios:
- Installing additional Python packages
- Adding custom system dependencies
- Modifying LightRAG configuration
- Adding custom scripts or hooks

## Development Workflow

### Adding/Updating Documents

1. Place documents in `./documents/` directory or use the API
2. Use `api_client_example.py` as reference for indexing
3. Documents are chunked, embedded, and knowledge graph is extracted automatically
4. Monitor indexing progress in logs: `docker-compose logs -f lightrag`

### Modifying LightRAG Configuration

1. Update `.env` file with new settings
2. Restart the lightrag service: `docker-compose restart lightrag`
3. For vLLM/embedding changes, restart those services: `docker-compose restart vllm embedding`

### Performance Tuning Scenarios

**For high-quality responses (low concurrent users):**
```yaml
# In docker-compose.yml, vllm service:
--gpu-memory-utilization 0.7
--max-model-len 32768
```

**For high throughput (many concurrent users):**
```yaml
# In docker-compose.yml, vllm service:
--gpu-memory-utilization 0.4
--max-model-len 16384
--max-num-seqs 16

# In .env:
MAX_ASYNC=8
```

**For memory constraints:**
```yaml
# In docker-compose.yml, vllm service:
--gpu-memory-utilization 0.3
--max-model-len 16384
```

## Troubleshooting

### Service won't start
- Check logs: `docker-compose logs [service_name]`
- Verify GPU: `nvidia-smi`
- Ensure NVIDIA Docker runtime is installed
- Check port conflicts: `lsof -i :9621` (or other ports)

### Out of GPU memory
- Reduce `--gpu-memory-utilization` in docker-compose.yml
- Decrease `--max-model-len` for vLLM
- Check GPU usage: `nvidia-smi`

### Slow query responses
- Enable reranker if not already: `ENABLE_RERANK=true`
- Increase `MAX_ASYNC` for parallel processing
- Use `hybrid` or `mix` mode instead of `global`
- Monitor GPU utilization with `nvidia-smi`

### PostgreSQL connection issues
- Verify postgres is healthy: `docker-compose ps`
- Check entrypoint.sh logs for startup sequence
- Ensure correct credentials in .env
- Test connection: `docker exec -it lightrag-postgres psql -U lightrag -d lightrag`

### API returns empty responses
- Verify documents are indexed: Check postgres `doc_status` table
- Ensure vLLM is responding: `curl http://localhost:8000/health`
- Check embedding service: `curl http://localhost:8001/health`
- Review query mode and parameters

## API Client Reference

See `api_client_example.py` for complete usage examples. Key methods:

```python
from api_client_example import CustomerSupportRAG

client = CustomerSupportRAG("http://localhost:9621")

# Health check
client.health_check()

# Index documents
client.index_documents(documents=["text"], doc_ids=["id"])

# Query (sync)
result = client.query("question", mode="hybrid")

# Query (streaming)
for chunk in client.stream_query("question", mode="hybrid"):
    print(chunk)

# Get entities
entities = client.get_entities()

# Delete document
client.delete_document("doc-id")
```

## Important Notes

- **Using official image**: LightRAG server uses `ghcr.io/hkuds/lightrag:latest` (no build required)
- First startup takes 5-10 minutes to download models (~23GB total for vLLM, embedding, reranker)
- LightRAG image is pulled automatically on first `docker-compose up`
- Models are cached in `./models/` directory
- Always use `hybrid` or `mix` mode with reranker for best quality
- **Change default PostgreSQL password before production deployment**
- The system supports streaming responses for real-time UX
- Document indexing time varies: ~10-30 seconds per document depending on size
- Knowledge graph extraction uses LLM, so it's GPU-accelerated
- To customize LightRAG, see "Customizing LightRAG (Advanced)" section
