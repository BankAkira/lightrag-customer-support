# 🚀 START HERE - RunPod Deployment

## You're Getting Docker Errors? Do This:

### **The Problem**
RunPod doesn't use systemd, so Docker needs to be started manually.

### **The Solution** (3 Simple Commands)

```bash
# 1. Start Docker
sudo service docker start

# 2. Verify it's running
docker ps

# 3. If step 2 worked, continue with deployment
```

---

## Complete Deployment (Copy & Paste)

```bash
# Step 1: Start Docker
sudo service docker start
docker ps  # Should show "CONTAINER ID   IMAGE   ..." header

# Step 2: Configure environment
cp .env.example .env
nano .env
# Change this line: POSTGRES_PASSWORD="your_secure_password_here"
# Make sure LANGUAGE="Thai and English" has quotes!
# Press Ctrl+X, then Y, then Enter to save

# Step 3: Make scripts executable
chmod +x *.sh

# Step 4: Deploy
bash deploy-runpod.sh
# This takes 5-10 minutes on first run (downloading models)

# Step 5: Check status (wait a few minutes after deploy)
bash status-runpod.sh
```

---

## Verify It's Working

```bash
# Check if all containers are running
docker ps

# Test the API
curl http://localhost:9621/health

# Should return: {"status":"healthy"}
```

---

## If Docker Won't Start

### Option 1: Use the helper script
```bash
bash start-docker.sh
```

### Option 2: Try different methods manually

```bash
# Method 1
sudo service docker start

# Method 2
sudo /etc/init.d/docker start

# Method 3
sudo dockerd &
```

### Option 3: Check if it's a permission issue

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Then logout and login again, OR:
newgrp docker

# Try without sudo
docker ps
```

---

## Common Errors & Fixes

### ❌ "and: command not found"

**Problem**: Your `.env` file has unquoted values

**Fix**:
```bash
nano .env

# Find this line:
LANGUAGE=Thai and English

# Change it to (with quotes!):
LANGUAGE="Thai and English"

# Also check:
ENTITY_TYPES='["organization", "person", "product"]'
```

### ❌ "docker: command not found"

**Fix**:
```bash
# Start Docker
sudo service docker start

# Verify
docker ps
```

### ❌ "permission denied"

**Fix**:
```bash
# Run with sudo
sudo bash deploy-runpod.sh
```

---

## What Gets Deployed?

When you run `deploy-runpod.sh`, it starts 5 containers:

1. **PostgreSQL** - Database
2. **vLLM** - Typhoon 2.5 LLM (~20GB download)
3. **BGE-M3** - Embeddings (~2GB download)
4. **BGE Reranker** - Result ranking (~1GB download)
5. **LightRAG** - Main API server

**Total download**: ~23GB (cached in `./models/` directory)

---

## Monitoring Progress

```bash
# Watch vLLM download Typhoon model
docker logs -f lightrag-vllm

# Watch embedding service
docker logs -f lightrag-embedding

# Watch main server
docker logs -f lightrag-server

# Watch GPU usage
watch -n 1 nvidia-smi
```

---

## After Deployment

### Test the system:

```bash
# Health check
curl http://localhost:9621/health

# Run example client
python api_client_example.py
```

### Access points:
- **API**: http://localhost:9621
- **API Docs**: http://localhost:9621/docs
- **vLLM**: http://localhost:8000

---

## Quick Commands Reference

```bash
# Start everything
sudo service docker start
bash deploy-runpod.sh

# Check status
bash status-runpod.sh
docker ps

# View logs
docker logs -f lightrag-server

# Stop everything (keeps data)
bash stop-runpod.sh

# Remove everything (deletes data!)
bash cleanup-runpod.sh

# Restart
bash deploy-runpod.sh
```

---

## Still Having Issues?

See these detailed guides:

1. **Docker problems**: `DOCKER_TROUBLESHOOTING.md`
2. **.env problems**: `ENV_TROUBLESHOOTING.md`
3. **Step-by-step guide**: `RUNPOD_QUICKSTART.md`
4. **Full documentation**: `RUNPOD_GUIDE.md`

Or run the diagnostic script:

```bash
bash setup-runpod.sh
```

---

## Success Checklist

- [ ] Docker is running (`docker ps` works)
- [ ] `.env` file created and password changed
- [ ] All scripts are executable (`chmod +x *.sh`)
- [ ] `deploy-runpod.sh` completed without errors
- [ ] All 5 containers are running (`docker ps` shows 5 containers)
- [ ] Health check works (`curl http://localhost:9621/health`)

---

**When all checks pass, your system is ready! 🎉**

Access the API at: http://localhost:9621
