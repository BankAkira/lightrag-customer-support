# 🚀 RunPod Deployment Guide for LightRAG Customer Support

Complete guide for deploying LightRAG Customer Support on RunPod **without docker-compose**.

## 📋 Prerequisites

- RunPod account with RTX Pro 6000 GPU pod (or similar)
- SSH access to your RunPod instance
- At least 200GB storage
- At least 96GB VRAM (for Typhoon 2.5 + embeddings + reranker)

## 🎯 Quick Start (3 Commands)

```bash
# 1. Copy .env.example to .env and edit password
cp .env.example .env
nano .env  # Change POSTGRES_PASSWORD

# 2. Make script executable and deploy
chmod +x deploy-runpod.sh
bash deploy-runpod.sh

# 3. Check status
bash status-runpod.sh
```

That's it! The system will deploy using pure Docker commands (no docker-compose needed).

## 📖 Detailed Deployment Steps

### Step 1: Connect to RunPod

```bash
# SSH into your RunPod instance
ssh root@<your-runpod-ip> -p <port>

# Navigate to workspace
cd /workspace
```

### Step 2: Upload/Clone Project Files

**Option A: Clone from Git**
```bash
git clone <your-repo-url> lightrag-support
cd lightrag-support
```

**Option B: Upload via SCP**
```bash
# On your local machine:
scp -P <port> -r ./* root@<runpod-ip>:/workspace/lightrag-support/

# Then on RunPod:
cd /workspace/lightrag-support
```

### Step 3: Configure Environment

```bash
# Copy template
cp .env.example .env

# Edit configuration
nano .env

# IMPORTANT: Change these values:
# - POSTGRES_PASSWORD=your_secure_password_here
# - Adjust GPU settings if needed
```

### Step 4: Deploy Services

```bash
# Make scripts executable
chmod +x *.sh

# Deploy all services (takes 5-10 minutes on first run)
bash deploy-runpod.sh
```

This script will:
1. ✅ Create Docker network
2. ✅ Start PostgreSQL with pgvector
3. ✅ Start vLLM (Typhoon 2.5) - downloads ~20GB model
4. ✅ Start BGE-M3 Embedding - downloads ~2GB model
5. ✅ Start BGE Reranker - downloads ~1GB model
6. ✅ Start LightRAG Server

### Step 5: Verify Deployment

```bash
# Check all services
bash status-runpod.sh

# Or manually:
docker ps
curl http://localhost:9621/health
curl http://localhost:8000/health
curl http://localhost:8001/health
```

### Step 6: Monitor First Startup

```bash
# Watch logs to see model downloads
docker logs -f lightrag-vllm      # Typhoon 2.5 loading
docker logs -f lightrag-embedding  # BGE-M3 loading
docker logs -f lightrag-server     # LightRAG startup

# Monitor GPU usage
watch -n 1 nvidia-smi
```

### Step 7: Test the System

```bash
# Run the example client
python api_client_example.py

# Or test with curl
curl -X POST http://localhost:9621/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Hello", "mode": "hybrid"}'
```

## 🛠️ Management Scripts

### Check Status
```bash
bash status-runpod.sh
```
Shows:
- Container status
- Health checks
- GPU usage
- Access points

### Stop Services
```bash
bash stop-runpod.sh
```
Stops all containers but **preserves data**.

### Restart Services
```bash
bash deploy-runpod.sh
```
Re-deploys everything (data is preserved).

### Clean Up Everything
```bash
bash cleanup-runpod.sh
```
⚠️ **WARNING**: Deletes all data including models, database, and documents.

## 📊 Service Ports

| Service | Port | URL |
|---------|------|-----|
| LightRAG API | 9621 | http://localhost:9621 |
| LightRAG Docs | 9621 | http://localhost:9621/docs |
| vLLM | 8000 | http://localhost:8000 |
| Embedding | 8001 | http://localhost:8001 |
| Reranker | 8002 | http://localhost:8002 |
| PostgreSQL | 5432 | localhost:5432 |

## 🔧 Configuration Tuning for RunPod

### GPU Memory Optimization

Edit `deploy-runpod.sh` to adjust GPU allocation:

```bash
# For RTX Pro 6000 (96GB VRAM)

# Option 1: High Quality (uses more GPU memory)
--gpu-memory-utilization 0.7
--max-model-len 32768

# Option 2: Balanced (default)
--gpu-memory-utilization 0.4
--max-model-len 32768

# Option 3: High Throughput (more concurrent users)
--gpu-memory-utilization 0.3
--max-model-len 16384
```

### Check GPU Usage

```bash
# Real-time monitoring
watch -n 1 nvidia-smi

# Memory usage by container
nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
```

## 🐛 Troubleshooting RunPod

### Issue: "Cannot connect to Docker daemon"

```bash
# Start Docker service
service docker start

# Or restart Docker
service docker restart
```

### Issue: "Out of GPU memory"

```bash
# Stop services
bash stop-runpod.sh

# Edit deploy-runpod.sh, find vLLM section, change:
--gpu-memory-utilization 0.3  # Reduce from 0.4

# Redeploy
bash deploy-runpod.sh
```

### Issue: "Models downloading slowly"

RunPod usually has good bandwidth, but if slow:

```bash
# Check download progress
docker logs -f lightrag-vllm

# The models are cached in ./models/
# If interrupted, just restart - it will resume
```

### Issue: "Service not starting"

```bash
# Check logs for specific service
docker logs lightrag-server
docker logs lightrag-vllm
docker logs lightrag-postgres

# Check if port is already in use
netstat -tlnp | grep 9621

# Remove conflicting container
docker rm -f <container-name>
```

### Issue: "PostgreSQL connection failed"

```bash
# Check if PostgreSQL is running
docker exec lightrag-postgres pg_isready -U lightrag

# If not, check logs
docker logs lightrag-postgres

# Restart PostgreSQL
docker restart lightrag-postgres
```

## 🔐 Security on RunPod

### Change Default Password

```bash
# Edit .env
nano .env

# Change:
POSTGRES_PASSWORD=your_very_secure_password_here

# Redeploy
bash deploy-runpod.sh
```

### Expose to Public Internet (Optional)

RunPod provides public URLs. To expose your service:

1. **Option 1: Use RunPod's HTTP Ports**
   - Configure in RunPod dashboard
   - Map port 9621 to public HTTP port

2. **Option 2: Use SSH Tunneling**
   ```bash
   # On your local machine:
   ssh -L 9621:localhost:9621 root@<runpod-ip> -p <port>

   # Access at: http://localhost:9621
   ```

3. **Option 3: Add nginx reverse proxy**
   ```bash
   # Install nginx
   apt-get update && apt-get install -y nginx

   # Configure reverse proxy (see DEPLOYMENT_GUIDE.md)
   ```

## 💰 RunPod Cost Optimization

### Pause When Not in Use

```bash
# Stop all services before pausing RunPod instance
bash stop-runpod.sh

# Data is preserved in:
# - Docker volume: postgres_data
# - Directories: ./models, ./lightrag_data, ./documents
```

When you resume:
```bash
# Models are already downloaded, starts quickly
bash deploy-runpod.sh
```

### Use Spot Instances

- Models and data are in `/workspace` which persists
- If spot instance terminates, data is preserved
- Just redeploy on new instance: `bash deploy-runpod.sh`

### Reduce Model Size (Advanced)

If 96GB is too expensive, use smaller models:

```bash
# Edit deploy-runpod.sh, change:
--model scb10x/typhoon-v2.5-instruct  # Current: ~40GB

# To smaller model:
--model microsoft/phi-3-medium-4k-instruct  # ~8GB
# or
--model mistralai/Mistral-7B-Instruct-v0.2  # ~14GB
```

## 📱 Accessing from Outside RunPod

### Method 1: RunPod Proxy (Easiest)

RunPod provides HTTP port forwarding:
1. Go to RunPod dashboard
2. Find your pod
3. Look for "HTTP Service" ports
4. Access via: `https://<pod-id>-9621.proxy.runpod.net`

### Method 2: SSH Tunnel (Most Secure)

```bash
# On your local machine:
ssh -N -L 9621:localhost:9621 root@<runpod-ip> -p <port>

# Access at: http://localhost:9621
```

### Method 3: Tailscale VPN (Advanced)

Install Tailscale on RunPod for private network access.

## 🎓 Alternative Deployment Options

### Option A: Install docker-compose

If you prefer docker-compose:

```bash
# Install docker-compose
bash install-docker-compose.sh

# Use docker-compose
source ~/.bashrc
docker-compose up -d
```

### Option B: Manual Installation (No Docker)

See `MANUAL_INSTALL.md` for Python virtual environment setup (advanced).

## 📞 Support & Logs

### View Logs

```bash
# All services
docker logs -f lightrag-server
docker logs -f lightrag-vllm
docker logs -f lightrag-embedding
docker logs -f lightrag-reranker
docker logs -f lightrag-postgres

# Last 100 lines
docker logs --tail 100 lightrag-server
```

### Export Logs

```bash
# Save logs to file
docker logs lightrag-server > lightrag-server.log 2>&1
docker logs lightrag-vllm > vllm.log 2>&1
```

### Get Help

1. Check logs first: `docker logs <container-name>`
2. Check status: `bash status-runpod.sh`
3. Check GPU: `nvidia-smi`
4. Review this guide's troubleshooting section

## ✅ Deployment Checklist

- [ ] RunPod instance with GPU (RTX Pro 6000 or similar)
- [ ] At least 200GB storage available
- [ ] Uploaded all project files
- [ ] Created `.env` from `.env.example`
- [ ] Changed `POSTGRES_PASSWORD` in `.env`
- [ ] Made scripts executable: `chmod +x *.sh`
- [ ] Ran: `bash deploy-runpod.sh`
- [ ] Verified: `bash status-runpod.sh`
- [ ] Tested: `curl http://localhost:9621/health`
- [ ] Tested API: `python api_client_example.py`

## 🎉 You're Done!

Your LightRAG Customer Support system is now running on RunPod with:
- ✅ No docker-compose required
- ✅ GPU-accelerated inference
- ✅ Multilingual support (Thai + English)
- ✅ Automatic model downloads
- ✅ Persistent data storage
- ✅ Easy management scripts

Access your system at: **http://localhost:9621** (or via RunPod proxy URL)
