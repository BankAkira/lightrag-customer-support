# 🚀 LightRAG Customer Support - RunPod Deployment (No Docker)

Complete setup guide for deploying LightRAG-based customer support system on RunPod **without Docker**.

## 📋 What You'll Get

✅ vLLM running Typhoon 2.5 (Thai/English LLM)  
✅ BGE-M3 multilingual embeddings  
✅ BGE Reranker V2 M3 for better results  
✅ PostgreSQL with pgvector  
✅ LightRAG server with Web UI  
✅ All services managed via tmux sessions  

## 🛠️ Step 1: Prepare RunPod Instance

### 1.1 Requirements
```
GPU: RTX Pro 6000 (96GB VRAM)
vCPU: 16+ cores
RAM: 64GB+
Storage: 200GB+ SSD
Template: PyTorch 2.x or CUDA 12.x
```

### 1.2 Connect via SSH
```bash
ssh root@<your-runpod-ip>
```

## 📦 Step 2: Upload and Install

### 2.1 Upload Files to RunPod
```bash
# On your local machine
scp -r ./* root@<your-runpod-ip>:/workspace/lightrag-setup/

# Or use RunPod's file browser to upload
```

### 2.2 Run Installation
```bash
# On RunPod instance
cd /workspace/lightrag-setup

# Make scripts executable
chmod +x install.sh setup_postgres.sh
chmod +x start_services.py stop_services.py

# Run installation (takes 5-10 minutes)
bash install.sh
```

**What gets installed:**
- LightRAG from GitHub
- vLLM for GPU-accelerated LLM inference
- Sentence Transformers for embeddings
- FlagEmbedding for reranking
- PostgreSQL with pgvector
- FastAPI for API servers

## 🗄️ Step 3: Setup PostgreSQL

```bash
# Start PostgreSQL
sudo service postgresql start

# Setup database and user
bash setup_postgres.sh

# Verify it's running
pg_isready
```

## ⚙️ Step 4: Configure Services

### 4.1 Check GPU
```bash
nvidia-smi

# You should see RTX Pro 6000 with 96GB VRAM
```

### 4.2 Adjust Memory (Optional)

Edit `start_services.py` if needed:

```python
# For vLLM service, adjust:
"--gpu-memory-utilization", "0.5",  # Use 40-50GB (adjust 0.3-0.7)
"--max-model-len", "32768",         # Context length
```

**Memory allocation guide:**
```
Total 96GB VRAM:
- vLLM (0.5 utilization): ~40-48GB
- BGE-M3 Embedding: ~3-4GB
- BGE Reranker: ~2GB
- Buffer: ~40GB free for scaling
```

## 🚀 Step 5: Start Services

### 5.1 Launch All Services
```bash
python start_services.py

# Or start specific services when prompted:
# 1. All services (recommended)
# 2. vLLM only
# 3. Embedding + Reranker only
# 4. LightRAG only
```

### 5.2 What Happens

The script will:
1. ✅ Check PostgreSQL is running
2. 🚀 Start vLLM server (port 8000) - downloads Typhoon 2.5 (~20GB)
3. 🧠 Start embedding server (port 8001) - downloads BGE-M3 (~2GB)
4. 🎯 Start reranker server (port 8002) - downloads Reranker (~1GB)
5. 🌐 Start LightRAG server (port 9621)

**First run takes 10-15 minutes** to download all models.

### 5.3 Monitor Services

```bash
# View all running sessions
tmux list-sessions

# Check logs in real-time
tail -f /workspace/lightrag-support/logs/vllm.log
tail -f /workspace/lightrag-support/logs/embedding.log
tail -f /workspace/lightrag-support/logs/reranker.log
tail -f /workspace/lightrag-support/logs/lightrag.log

# Attach to a service (Ctrl+B then D to detach)
tmux attach -t vllm-server
tmux attach -t embedding-server
tmux attach -t reranker-server
tmux attach -t lightrag-server
```

## 🧪 Step 6: Test Your Setup

### 6.1 Health Check
```bash
# Check vLLM
curl http://localhost:8000/health

# Check embedding
curl http://localhost:8001/health

# Check reranker
curl http://localhost:8002/health

# Check LightRAG
curl http://localhost:9621/health
```

### 6.2 Test with Python Client
```bash
# Make sure you're in the working directory
cd /workspace/lightrag-support

# Run example client
python api_client_example.py
```

### 6.3 Access Web UI
```bash
# Open in your browser
http://<your-runpod-ip>:9621

# You should see LightRAG Web UI
```

## 📊 Step 7: Monitor GPU Usage

```bash
# Watch GPU in real-time
watch -n 1 nvidia-smi

# Expected GPU usage:
# Initial (idle): 25-35GB
# During queries: 35-50GB
```

## 📚 Step 8: Index Your Documents

### 8.1 Via Python API
```python
from api_client_example import CustomerSupportRAG

client = CustomerSupportRAG("http://localhost:9621")

# Check connection
if client.health_check():
    print("✅ Connected!")

# Index Thai document
thai_doc = """
สินค้า: AI Chat Support Pro
ฟีเจอร์:
- รองรับภาษาไทยและอังกฤษ
- ตอบคำถามอัตโนมัติ 24/7
- ใช้เทคโนโลยี RAG
"""

client.index_documents([thai_doc], doc_ids=["product-th-001"])

# Query in Thai
answer = client.query("สินค้านี้มีฟีเจอร์อะไรบ้าง?", mode="hybrid")
print(answer['response'])
```

### 8.2 Via Web UI
1. Go to `http://<your-ip>:9621`
2. Upload documents via the interface
3. Wait for indexing to complete
4. Start querying!

## 🛑 Step 9: Manage Services

### Stop All Services
```bash
python stop_services.py
```

### Stop Individual Service
```bash
tmux kill-session -t vllm-server
tmux kill-session -t embedding-server
tmux kill-session -t reranker-server
tmux kill-session -t lightrag-server
```

### Restart a Service
```bash
# Stop it first
tmux kill-session -t vllm-server

# Start again
python start_services.py
# Then select option 2 (vLLM only)
```

### View Service Logs
```bash
# Real-time logs
tail -f /workspace/lightrag-support/logs/vllm.log

# Last 100 lines
tail -n 100 /workspace/lightrag-support/logs/lightrag.log

# Search logs
grep "error" /workspace/lightrag-support/logs/*.log
```

## 🔧 Step 10: Optimization

### 10.1 For Maximum Quality
```python
# Edit start_services.py, vLLM config:
"--gpu-memory-utilization", "0.7",  # Use more GPU
"--max-model-len", "32768",
```

### 10.2 For High Throughput
```python
# Edit start_services.py, vLLM config:
"--gpu-memory-utilization", "0.4",  # Use less GPU per request
"--max-model-len", "16384",         # Shorter context
"--max-num-seqs", "16",             # More parallel requests
```

### 10.3 Use Different Model
```python
# Edit start_services.py, change model:
"--model", "your-model-name",
# Example: "openthaigpt/openthaigpt-1.0.0-beta-13b-chat"
```

## 🐛 Troubleshooting

### Problem: GPU Not Detected
```bash
# Check CUDA
nvidia-smi

# Check PyTorch can see GPU
python -c "import torch; print(torch.cuda.is_available())"

# If False, reinstall PyTorch:
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

### Problem: Out of Memory
```bash
# Check GPU usage
nvidia-smi

# Reduce vLLM memory in start_services.py:
"--gpu-memory-utilization", "0.3",  # Lower value
```

### Problem: vLLM Won't Start
```bash
# Check logs
cat /workspace/lightrag-support/logs/vllm.log

# Common fix: Model not found
# Make sure model name is correct in start_services.py

# Try with smaller model:
"--model", "scb10x/llama-3-typhoon-v1.5x-8b-instruct",
```

### Problem: Service Not Responding
```bash
# Check if process is running
tmux list-sessions

# Check logs for errors
tail -n 50 /workspace/lightrag-support/logs/<service>.log

# Restart the service
tmux kill-session -t <service-name>
python start_services.py
```

### Problem: PostgreSQL Connection Failed
```bash
# Check if PostgreSQL is running
sudo service postgresql status

# Start it
sudo service postgresql start

# Check connection
pg_isready -h localhost -p 5432 -U lightrag
```

### Problem: Slow Response
```bash
# Check GPU usage
nvidia-smi

# Check if GPU is actually being used
# vLLM log should show: "Using GPU"

# Increase parallel processing
# Edit start_services.py vLLM:
"--max-num-batched-tokens", "8192",
```

## 🌐 Production Deployment

### Enable Public Access
```bash
# Make sure RunPod ports are exposed
# In RunPod dashboard: Edit Pod → TCP Ports
# Add: 9621 (LightRAG UI)
```

### Add SSL/TLS (Optional)
```bash
# Install Caddy
apt install -y caddy

# Create Caddyfile
cat > /etc/caddy/Caddyfile << EOF
:443 {
    reverse_proxy localhost:9621
    tls internal
}
EOF

# Start Caddy
systemctl start caddy
```

### Secure PostgreSQL
```bash
# Change password
sudo -u postgres psql -c "ALTER USER lightrag PASSWORD 'your-strong-password';"

# Update in lightrag_server.py:
os.environ["POSTGRES_PASSWORD"] = "your-strong-password"
```

## 📈 Performance Tips

### For RTX Pro 6000 (96GB):

**Best Practices:**
1. Start with `gpu-memory-utilization=0.5` (balanced)
2. Monitor with `nvidia-smi` during usage
3. Adjust based on concurrent user count
4. Use reranker for better quality results
5. Enable LLM caching for faster responses

**Benchmarks (estimated):**
- Model loading: 2-3 minutes
- Document indexing: 10-30s per document
- Query response: 2-5 seconds
- Concurrent users: 10-20+

## 🔐 Security Checklist

- [ ] Changed PostgreSQL password
- [ ] Services bound to localhost (use reverse proxy for public)
- [ ] Setup firewall rules
- [ ] Enable authentication on LightRAG API
- [ ] Regular backups of PostgreSQL
- [ ] Monitor logs for suspicious activity
- [ ] Keep dependencies updated

## 📞 Quick Reference

### Service Ports
```
8000 - vLLM (Typhoon 2.5)
8001 - BGE-M3 Embeddings
8002 - BGE Reranker
9621 - LightRAG Server + Web UI
5432 - PostgreSQL
```

### Important Paths
```
/workspace/lightrag-support/          - Main directory
/workspace/lightrag-support/logs/     - Service logs
/workspace/lightrag-support/LightRAG/ - LightRAG source
/workspace/lightrag-support/lightrag_data/ - RAG data
```

### Key Commands
```bash
# Start all
python start_services.py

# Stop all
python stop_services.py

# View logs
tail -f logs/<service>.log

# Check GPU
nvidia-smi

# List sessions
tmux list-sessions

# Attach to service
tmux attach -t <service-name>
```

## 🎉 You're Done!

Your LightRAG customer support system is now running on RunPod with:
- ✅ Typhoon 2.5 LLM (Thai + English)
- ✅ GPU-accelerated inference
- ✅ Multilingual embeddings
- ✅ Smart reranking
- ✅ Persistent storage
- ✅ Easy management via tmux

Start indexing your documents and let your customers ask questions! 🚀

## 💡 Next Steps

1. Index your product documentation
2. Test with real customer questions
3. Monitor performance and adjust GPU settings
4. Setup backups for PostgreSQL
5. Consider adding authentication
6. Integrate with your existing systems

Need help? Check the logs and troubleshooting section above! 📚
