# RunPod Quick Start - Simple Version

**Having Docker issues? Follow this simple guide.**

## Step 1: Start Docker Manually

RunPod doesn't use systemd, so you need to start Docker manually:

```bash
# Just run this one command:
sudo service docker start

# Verify it's running:
docker ps
```

If that doesn't work:

```bash
# Try the helper script:
bash start-docker.sh
```

## Step 2: Configure Environment

```bash
# Copy template
cp .env.example .env

# Edit and change POSTGRES_PASSWORD
nano .env
```

**Important**: Change these lines in `.env`:
```bash
POSTGRES_PASSWORD="your_secure_password_here"
LANGUAGE="Thai and English"
ENTITY_TYPES='["organization", "person", "product", "service"]'
```

## Step 3: Deploy

```bash
# Make scripts executable
chmod +x *.sh

# Deploy (might need sudo)
bash deploy-runpod.sh

# If that fails with permission denied:
sudo bash deploy-runpod.sh
```

## Step 4: Check Status

```bash
# See if everything is running
docker ps

# Or use the status script
bash status-runpod.sh
```

## Step 5: Test

```bash
# Wait a few minutes for models to download, then:
curl http://localhost:9621/health

# Should return: {"status":"healthy"}
```

---

## Common Issues

### "docker: command not found"

```bash
# Start Docker first:
sudo service docker start

# Verify:
docker ps
```

### "and: command not found"

Your `.env` file has unquoted values. Fix it:

```bash
# Edit .env
nano .env

# Make sure LANGUAGE line looks like this:
LANGUAGE="Thai and English"

# Not like this:
# LANGUAGE=Thai and English  ❌
```

### "permission denied"

Run with sudo:

```bash
sudo bash deploy-runpod.sh
```

### Services not starting

Check logs:

```bash
docker logs lightrag-server
docker logs lightrag-vllm
docker logs lightrag-postgres
```

---

## Full Manual Deployment (If Scripts Fail)

If the scripts don't work, here's the manual way:

### 1. Start Docker
```bash
sudo service docker start
```

### 2. Create Network
```bash
docker network create lightrag-network
```

### 3. Start PostgreSQL
```bash
docker run -d \
  --name lightrag-postgres \
  --network lightrag-network \
  -p 5432:5432 \
  -e POSTGRES_DB=lightrag \
  -e POSTGRES_USER=lightrag \
  -e POSTGRES_PASSWORD=your_password_here \
  -v postgres_data:/var/lib/postgresql/data \
  --restart unless-stopped \
  pgvector/pgvector:pg16
```

### 4. Start vLLM (may take 10 minutes to download model)
```bash
docker run -d \
  --name lightrag-vllm \
  --network lightrag-network \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/models:/root/.cache/huggingface \
  --shm-size 4g \
  --restart unless-stopped \
  vllm/vllm-openai:latest \
  --model scb10x/typhoon-v2.5-instruct \
  --host 0.0.0.0 \
  --port 8000 \
  --gpu-memory-utilization 0.4 \
  --max-model-len 32768
```

### 5. Start Embedding
```bash
docker run -d \
  --name lightrag-embedding \
  --network lightrag-network \
  --gpus all \
  -p 8001:80 \
  -e MODEL_ID=BAAI/bge-m3 \
  -v $(pwd)/models/embeddings:/data \
  --restart unless-stopped \
  ghcr.io/huggingface/text-embeddings-inference:1.5
```

### 6. Start Reranker
```bash
docker run -d \
  --name lightrag-reranker \
  --network lightrag-network \
  --gpus all \
  -p 8002:80 \
  -e MODEL_ID=BAAI/bge-reranker-v2-m3 \
  -v $(pwd)/models/reranker:/data \
  --restart unless-stopped \
  ghcr.io/huggingface/text-embeddings-inference:1.5
```

### 7. Start LightRAG (wait for other services to be ready first)
```bash
# Wait a few minutes for vLLM, embedding, and reranker to download models
# Then:

docker run -d \
  --name lightrag-server \
  --network lightrag-network \
  -p 9621:9621 \
  -e LLM_MODEL_NAME=scb10x/typhoon-v2.5-instruct \
  -e LLM_BASE_URL=http://lightrag-vllm:8000/v1 \
  -e EMBEDDING_MODEL=BAAI/bge-m3 \
  -e EMBEDDING_BASE_URL=http://lightrag-embedding:80 \
  -e RERANKER_BASE_URL=http://lightrag-reranker:80 \
  -e POSTGRES_HOST=lightrag-postgres \
  -e POSTGRES_USER=lightrag \
  -e POSTGRES_PASSWORD=your_password_here \
  -e POSTGRES_DATABASE=lightrag \
  -e LANGUAGE="Thai and English" \
  -v $(pwd)/lightrag_data:/app/lightrag_data \
  --restart unless-stopped \
  ghcr.io/hkuds/lightrag:latest
```

### 8. Check Status
```bash
docker ps
docker logs -f lightrag-server
```

---

## Next Steps

Once everything is running:

```bash
# Test the API
curl http://localhost:9621/health

# Run the example client
python api_client_example.py

# Access the web UI (if you have port forwarding):
# http://localhost:9621
```

---

## Need Help?

1. **Docker not starting**: See `DOCKER_TROUBLESHOOTING.md`
2. **.env errors**: See `ENV_TROUBLESHOOTING.md`
3. **Full guide**: See `RUNPOD_GUIDE.md`

---

## TL;DR - Absolute Minimal Commands

```bash
# 1. Start Docker
sudo service docker start

# 2. Configure
cp .env.example .env
nano .env  # Change password

# 3. Deploy
chmod +x *.sh
bash deploy-runpod.sh

# 4. Wait 5-10 minutes for models to download

# 5. Test
curl http://localhost:9621/health
```

Done! 🎉
