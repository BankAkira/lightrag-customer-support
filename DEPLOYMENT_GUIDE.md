# 🚀 LightRAG Customer Support - RunPod RTX 6000 Deployment Guide

Complete setup guide for deploying LightRAG-based customer support system on RunPod with RTX Pro 6000 (96GB VRAM).

## 📋 Prerequisites

- RunPod account with RTX Pro 6000 GPU pod
- SSH access to your RunPod instance
- Basic knowledge of Docker and Docker Compose

## 🛠️ Step 1: Configure RunPod Instance

### 1.1 Create RunPod Pod
```bash
# Recommended specs for RunPod:
- GPU: RTX Pro 6000 (96GB VRAM)
- CPU: 16+ vCPUs
- RAM: 64GB+
- Storage: 200GB+ SSD

# Template: PyTorch or CUDA with Docker support
```

### 1.2 Install NVIDIA Docker Runtime (if not installed)
```bash
# Connect to your RunPod instance via SSH
ssh root@<your-runpod-ip>

# Check if NVIDIA Docker runtime is available
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi

# If the above works, you're good to go!
```

## 📦 Step 2: Setup Project

### 2.1 Upload Files to RunPod
```bash
# On your local machine, create project directory
mkdir lightrag-customer-support
cd lightrag-customer-support

# Copy all files:
# - docker-compose.yml
# - Dockerfile
# - .env
# - entrypoint.sh
# - api_client_example.py

# Upload to RunPod (replace with your pod IP)
scp -r ./* root@<your-runpod-ip>:/workspace/lightrag-support/
```

### 2.2 Or Clone from Your Git Repository
```bash
# On RunPod instance
cd /workspace
git clone <your-repo-url> lightrag-support
cd lightrag-support
```

## ⚙️ Step 3: Configure for GPU

### 3.1 Verify GPU Configuration
```bash
# Check GPU availability
nvidia-smi

# Expected output: RTX Pro 6000 with 96GB VRAM
```

### 3.2 Update docker-compose.yml GPU Settings (Optional)
```yaml
# For RTX Pro 6000 with 96GB VRAM, you can adjust:

vllm:
  command: >
    --model scb10x/typhoon-v2.5-instruct
    --tensor-parallel-size 1          # Use 1 GPU
    --gpu-memory-utilization 0.5      # Adjust based on your needs (0.3-0.7)
    --max-model-len 32768             # Context length
    --dtype auto                       # Or float16/bfloat16
```

### 3.3 Memory Allocation Strategy
```
Total 96GB VRAM allocation example:
- vLLM (Typhoon 2.5): ~40GB (gpu-memory-utilization: 0.4-0.5)
- BGE-M3 Embedding: ~4GB
- BGE Reranker: ~2GB
- System overhead: ~2GB
- Free buffer: ~48GB (for future scaling or batch processing)
```

## 🚀 Step 4: Deploy

### 4.1 Make Scripts Executable
```bash
chmod +x entrypoint.sh
```

### 4.2 Start Services
```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Wait for all services to be healthy (may take 5-10 minutes on first run)
# vLLM will download Typhoon 2.5 model (~20GB)
# Embedding service will download BGE-M3 (~2GB)
# Reranker will download BGE Reranker (~1GB)
```

### 4.3 Verify Services
```bash
# Check all containers are running
docker-compose ps

# Should show:
# - lightrag-vllm (healthy)
# - lightrag-embedding (healthy)
# - lightrag-reranker (running)
# - lightrag-postgres (healthy)
# - lightrag-server (running)

# Test vLLM endpoint
curl http://localhost:8000/health

# Test embedding endpoint
curl http://localhost:8001/health

# Test LightRAG server
curl http://localhost:9621/health
```

## 🧪 Step 5: Test Your Setup

### 5.1 Install Python Client Dependencies
```bash
pip install requests
```

### 5.2 Run Example Client
```bash
python api_client_example.py
```

### 5.3 Access Web UI
```bash
# Open in browser
http://<your-runpod-ip>:9621

# You should see the LightRAG Web UI
```

## 📊 Step 6: Monitor GPU Usage

### 6.1 Real-time Monitoring
```bash
# Watch GPU usage
watch -n 1 nvidia-smi

# Check memory usage of each container
docker stats
```

### 6.2 Expected GPU Usage
```
Initial state (idle):
- vLLM: ~20-30GB (model loaded)
- Embedding: ~2-4GB
- Reranker: ~1-2GB

During query:
- vLLM: +5-15GB (depending on context length)
- Embedding: +1-2GB (during batch processing)
```

## 🔧 Step 7: Optimize for Your Needs

### 7.1 Adjust GPU Memory for vLLM
```bash
# Edit docker-compose.yml
# Change --gpu-memory-utilization based on your workload

# For heavy concurrent users:
--gpu-memory-utilization 0.7  # Use more GPU memory

# For light usage:
--gpu-memory-utilization 0.3  # Leave room for other services
```

### 7.2 Scale Embedding Service
```bash
# If you need faster embedding processing, you can use tensor parallel
# But BGE-M3 is relatively small, so usually not necessary
```

### 7.3 Use Different LLM Models
```bash
# To use different models, update docker-compose.yml:
vllm:
  command: >
    --model <your-model-path>
    # For larger models like Typhoon 2.5 72B, use tensor-parallel-size 2
    --tensor-parallel-size 2
```

## 🌐 Step 8: Production Deployment

### 8.1 Enable SSL/TLS
```bash
# Use nginx reverse proxy or Caddy
# Example with Caddy:
docker run -d \
  -p 80:80 -p 443:443 \
  -v $PWD/Caddyfile:/etc/caddy/Caddyfile \
  caddy:latest
```

### 8.2 Setup Domain (Optional)
```bash
# Point your domain to RunPod IP
# Update Caddyfile:
your-domain.com {
    reverse_proxy localhost:9621
}
```

### 8.3 Add Authentication
```bash
# Add API key authentication to LightRAG
# Update .env:
ENABLE_AUTH=true
API_KEY=your-secret-api-key
```

## 📝 Step 9: Index Your Documents

### 9.1 Prepare Documents
```bash
# Create documents directory
mkdir -p documents

# Add your product docs (PDF, DOCX, TXT, etc.)
# Place them in ./documents/
```

### 9.2 Index Documents via API
```python
from api_client_example import CustomerSupportRAG

client = CustomerSupportRAG("http://localhost:9621")

# Read and index your documents
with open("documents/product_manual_th.txt", "r") as f:
    content = f.read()
    client.index_documents([content], doc_ids=["manual-th-001"])
```

### 9.3 Or Use Web UI
```bash
# Navigate to http://<your-ip>:9621
# Use the document upload feature
```

## 🐛 Troubleshooting

### Common Issues:

**1. GPU not detected**
```bash
# Check NVIDIA runtime
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi

# Install NVIDIA Container Toolkit if needed
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

**2. Out of Memory (OOM)**
```bash
# Reduce vLLM memory usage
# Edit docker-compose.yml, change:
--gpu-memory-utilization 0.3  # Lower value

# Or reduce max model length:
--max-model-len 16384  # Instead of 32768
```

**3. vLLM fails to start**
```bash
# Check logs
docker-compose logs vllm

# Common fix: Update model name or path
# Make sure the model is compatible with vLLM
```

**4. Slow response times**
```bash
# Enable more parallel processing
# Update .env:
MAX_ASYNC=8  # Increase from 4

# Or use faster embedding model
EMBEDDING_MODEL=BAAI/bge-small-en-v1.5  # Smaller but faster
```

**5. Services not connecting**
```bash
# Check if all services are in the same network
docker-compose ps
docker network ls

# Restart services
docker-compose down
docker-compose up -d
```

## 📈 Performance Tuning

### For RTX Pro 6000 (96GB VRAM):

**Configuration A: Maximum Quality**
```yaml
vllm:
  --gpu-memory-utilization 0.7
  --max-model-len 32768
  --dtype auto
# Use for: High-quality responses, complex queries
```

**Configuration B: Balanced**
```yaml
vllm:
  --gpu-memory-utilization 0.5
  --max-model-len 24576
  --dtype float16
# Use for: Production with moderate load
```

**Configuration C: High Throughput**
```yaml
vllm:
  --gpu-memory-utilization 0.4
  --max-model-len 16384
  --max-num-seqs 16  # Process multiple requests in parallel
# Use for: Many concurrent users
```

## 🔐 Security Checklist

- [ ] Change default PostgreSQL password in .env
- [ ] Enable API authentication
- [ ] Setup firewall rules (allow only necessary ports)
- [ ] Use HTTPS in production
- [ ] Regularly backup PostgreSQL data
- [ ] Monitor logs for suspicious activity
- [ ] Keep Docker images updated

## 📞 Support

If you encounter any issues:
1. Check logs: `docker-compose logs -f [service_name]`
2. Verify GPU: `nvidia-smi`
3. Check service health: `curl http://localhost:9621/health`

## 🎉 You're Done!

Your LightRAG customer support system is now running on RunPod with:
- ✅ Typhoon 2.5 LLM via vLLM
- ✅ Multilingual support (Thai + English)
- ✅ BGE-M3 embeddings
- ✅ BGE Reranker for better results
- ✅ PostgreSQL for persistent storage
- ✅ GPU-accelerated inference

Start indexing your documents and let your customers ask questions! 🚀
