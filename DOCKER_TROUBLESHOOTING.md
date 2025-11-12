# Docker Troubleshooting on RunPod

Quick solutions for Docker-related issues on RunPod.

## ❌ Error: "docker: command not found"

### Problem
```bash
deploy-runpod.sh: line 51: docker: command not found
```

### Solutions

#### Solution 1: Start Docker Service (Most Common)

Docker might be installed but not running:

```bash
# Start Docker
sudo service docker start

# Verify it's running
docker ps

# If that works, run deploy again:
bash deploy-runpod.sh
```

#### Solution 2: Use the Setup Script

We have a script that handles this automatically:

```bash
bash setup-runpod.sh
```

This will:
- ✅ Check if Docker is installed
- ✅ Start Docker if needed
- ✅ Verify GPU access
- ✅ Check disk space
- ✅ Show what to do next

#### Solution 3: Check Docker Path

Docker might be installed in a non-standard location:

```bash
# Find Docker
which docker
ls -la /usr/bin/docker

# If found, add to PATH
export PATH=$PATH:/usr/bin
source ~/.bashrc

# Try again
docker --version
```

#### Solution 4: Install Docker (If Really Missing)

RunPod should have Docker pre-installed, but if not:

```bash
# Download and install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Start Docker
sudo service docker start

# Verify
docker --version
docker ps
```

## ❌ Error: "Cannot connect to the Docker daemon"

### Problem
```bash
Cannot connect to the Docker daemon at unix:///var/run/docker.sock.
Is the docker daemon running?
```

### Solution

Start the Docker daemon:

```bash
# Method 1: Using service
sudo service docker start

# Method 2: Using systemctl (if available)
sudo systemctl start docker
sudo systemctl enable docker

# Verify it's running
docker ps
```

### If Still Not Working

Check Docker status:

```bash
# Check status
sudo service docker status

# Check logs
sudo journalctl -u docker -n 50

# Restart Docker
sudo service docker restart
```

## ❌ Error: "permission denied while trying to connect to Docker"

### Problem
```bash
Got permission denied while trying to connect to the Docker daemon socket
```

### Solution

Add your user to the docker group:

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes (logout/login or use newgrp)
newgrp docker

# Or just use sudo for now
sudo bash deploy-runpod.sh
```

## 🎮 GPU Not Accessible from Docker

### Problem
Docker can't access the GPU

### Check GPU

```bash
# Check if GPU is visible on host
nvidia-smi

# Check if Docker can access GPU
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

### Solution

Install NVIDIA Container Toolkit:

```bash
# Add repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Restart Docker
sudo systemctl restart docker

# Test
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

## 💾 Out of Disk Space

### Problem
```bash
Error response from daemon: no space left on device
```

### Check Space

```bash
# Check disk usage
df -h /workspace

# Check Docker disk usage
docker system df
```

### Clean Up

```bash
# Remove unused Docker resources
docker system prune -a

# Remove specific containers
docker ps -a  # List all containers
docker rm <container-id>

# Remove specific images
docker images
docker rmi <image-id>

# Remove volumes
docker volume ls
docker volume rm <volume-name>
```

## 🔄 Docker Service Keeps Stopping

### Problem
Docker stops after a few minutes

### Solution

Enable Docker to start on boot:

```bash
# Enable Docker service
sudo systemctl enable docker

# Start it now
sudo systemctl start docker

# Check status
sudo systemctl status docker
```

## 🧹 Complete Docker Reset

### Nuclear Option (Use with Caution!)

If nothing else works:

```bash
# Stop all containers
docker stop $(docker ps -aq) 2>/dev/null

# Remove all containers
docker rm $(docker ps -aq) 2>/dev/null

# Remove all images
docker rmi $(docker images -q) 2>/dev/null

# Remove all volumes
docker volume prune -f

# Remove all networks
docker network prune -f

# Restart Docker
sudo service docker restart

# Verify
docker ps
docker images
```

## 📋 Pre-Deployment Checklist

Before running `deploy-runpod.sh`:

```bash
# 1. Check Docker is installed
docker --version

# 2. Check Docker daemon is running
docker ps

# 3. Check GPU access
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi

# 4. Check disk space (need 50GB+)
df -h /workspace

# 5. Run setup script
bash setup-runpod.sh
```

## 🚀 Quick Fix Command

Try this one-liner to fix most issues:

```bash
sudo service docker start && docker ps && bash setup-runpod.sh
```

## 🆘 Still Having Issues?

1. **Run the setup script:**
   ```bash
   bash setup-runpod.sh
   ```

2. **Check Docker installation:**
   ```bash
   docker --version
   docker ps
   docker info
   ```

3. **Check logs:**
   ```bash
   sudo journalctl -u docker -n 100
   ```

4. **Contact RunPod Support:**
   - Discord: https://discord.gg/runpod
   - Docs: https://docs.runpod.io/

## 💡 RunPod-Specific Tips

### RunPod Environment

- Docker is usually pre-installed on RunPod pods
- GPU access is pre-configured with NVIDIA Docker runtime
- `/workspace` is persistent storage
- Most RunPod templates include Docker

### Template Selection

When creating a RunPod pod:
- Choose a template with "Docker" in the name
- Or use "PyTorch" or "TensorFlow" templates (include Docker)
- Avoid "Jupyter" only templates (may not have Docker)

### Port Forwarding

To access from outside RunPod:
- Use RunPod's HTTP port forwarding
- Configure in RunPod dashboard
- Access via: `https://<pod-id>-9621.proxy.runpod.net`
