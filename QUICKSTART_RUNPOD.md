# ⚡ RunPod Quick Start (3 Commands)

Deploy LightRAG Customer Support on RunPod **without docker-compose** in 3 simple commands:

## 🚀 Installation (30 seconds)

```bash
# 1. Setup RunPod environment (checks Docker, GPU, disk space)
chmod +x *.sh
bash setup-runpod.sh

# 2. Configure environment
cp .env.example .env
nano .env  # Change POSTGRES_PASSWORD to something secure

# 3. Validate configuration (optional but recommended)
bash validate-env.sh

# 4. Deploy everything (takes 5-10 minutes on first run)
bash deploy-runpod.sh

# 5. Check status
bash status-runpod.sh
```

That's it! Your system is now running on:
- **API**: http://localhost:9621
- **Docs**: http://localhost:9621/docs

## 📝 Common Commands

```bash
# Check status
bash status-runpod.sh

# View logs
docker logs -f lightrag-server

# Stop everything
bash stop-runpod.sh

# Restart
bash deploy-runpod.sh

# Clean up all data (WARNING!)
bash cleanup-runpod.sh
```

## 🧪 Test It

```bash
# Option 1: Use the example client
python api_client_example.py

# Option 2: Quick curl test
curl -X POST http://localhost:9621/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Hello", "mode": "hybrid"}'
```

## 📚 More Info

- Full guide: [RUNPOD_GUIDE.md](RUNPOD_GUIDE.md)
- Troubleshooting: See [RUNPOD_GUIDE.md#troubleshooting](RUNPOD_GUIDE.md#-troubleshooting-runpod)
- API docs: http://localhost:9621/docs (when running)

## ⚙️ What Gets Deployed?

✅ PostgreSQL + pgvector (database)
✅ vLLM (Typhoon 2.5 LLM) - ~20GB download
✅ BGE-M3 (embeddings) - ~2GB download
✅ BGE Reranker - ~1GB download
✅ LightRAG Server (API + web UI)

Total: ~23GB of models (cached in `./models/`)

## 🎯 First Run Takes 5-10 Minutes

The first deployment downloads all models. Watch progress:

```bash
docker logs -f lightrag-vllm      # Typhoon 2.5 download
docker logs -f lightrag-embedding  # BGE-M3 download
```

Subsequent starts are **much faster** (models are cached).

## 🔐 Important Security Note

⚠️ **Change the default PostgreSQL password** in `.env` before deploying:

```bash
nano .env
# Change: POSTGRES_PASSWORD=your_secure_password_here
```

## 🆘 Quick Troubleshooting

**GPU not detected?**
```bash
nvidia-smi  # Should show your GPU
```

**Out of memory?**
```bash
# Edit deploy-runpod.sh, find this line and reduce value:
--gpu-memory-utilization 0.4  # Change to 0.3
```

**Service not starting?**
```bash
docker logs <service-name>  # Check logs
bash status-runpod.sh       # See what's running
```

## 🌐 Access from Outside RunPod

**Option 1: SSH Tunnel** (most secure)
```bash
# On your local machine:
ssh -N -L 9621:localhost:9621 root@<runpod-ip> -p <port>

# Then access: http://localhost:9621
```

**Option 2: RunPod HTTP Proxy**
- Configure in RunPod dashboard
- Access via: `https://<pod-id>-9621.proxy.runpod.net`

---

**Need help?** See full guide: [RUNPOD_GUIDE.md](RUNPOD_GUIDE.md)
