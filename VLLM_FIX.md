# 🔧 vLLM Error Fix Guide

If you see the error: `RuntimeError: Tried to instantiate class '_core_C.ScalarType'`, here are multiple solutions.

## 🎯 Quick Fixes (Choose One)

### Option 1: Use Compatible vLLM Version (Recommended)

```bash
# Uninstall current vLLM
pip uninstall vllm -y

# Install compatible version
pip install vllm==0.5.4 --no-build-isolation

# Restart vLLM service
tmux kill-session -t vllm-server
python start_services.py
# Choose option 2 (vLLM only)
```

### Option 2: Use Ollama Instead (Easiest)

Ollama is simpler and more stable for RunPod:

```bash
# Setup Ollama
python setup_ollama.py

# Update LightRAG to use Ollama
# Edit lightrag_server.py, change lines 7-9:
os.environ["LLM_MODEL_NAME"] = "typhoon2-32k"
os.environ["LLM_BASE_URL"] = "http://localhost:11434/v1"
os.environ["LLM_API_KEY"] = "dummy"

# Start services (skip vLLM)
python start_services.py
# Choose option 3 (Embedding + Reranker only)
# Then manually start LightRAG:
python lightrag_server.py
```

### Option 3: Use HuggingFace Transformers Directly

Skip vLLM entirely and use transformers:

```bash
pip install transformers accelerate

# Create simple LLM server
python hf_llm_server.py
```

## 🔍 Understanding the Error

The error happens because:
1. vLLM version mismatch with PyTorch/CUDA
2. PyTorch custom ops not registered properly
3. RunPod's pre-installed PyTorch might conflict

## 📊 Solution Comparison

| Solution | Speed | Memory | Ease | Stability |
|----------|-------|--------|------|-----------|
| vLLM 0.5.4 | ⚡⚡⚡ | 🟢 Good | 🟡 Medium | 🟢 Good |
| Ollama | ⚡⚡ | 🟢 Good | 🟢 Easy | 🟢 Great |
| Transformers | ⚡ | 🔴 High | 🟢 Easy | 🟢 Great |

## ✅ Option 1 Detailed: Fix vLLM

### Step 1: Clean Installation
```bash
# Stop all services
python stop_services.py

# Remove vLLM
pip uninstall vllm -y

# Check PyTorch version
python -c "import torch; print(torch.__version__)"
# Should be 2.x with cu121

# Install compatible vLLM
pip install vllm==0.5.4 --no-build-isolation
```

### Step 2: Verify Installation
```bash
python -c "import vllm; print(vllm.__version__)"
# Should print: 0.5.4

# Test basic import
python -c "from vllm import LLM; print('OK')"
```

### Step 3: Update start_services.py

Edit the vLLM command in `start_services.py` to use simpler parameters:

```python
"vllm": {
    "name": "vllm-server",
    "command": [
        "python", "-m", "vllm.entrypoints.openai.api_server",
        "--model", "scb10x/typhoon-v2.5-instruct",
        "--host", "0.0.0.0",
        "--port", "8000",
        "--gpu-memory-utilization", "0.5",
        "--max-model-len", "8192",  # Reduce to 8k for stability
        "--dtype", "float16"         # Use explicit dtype
    ],
    ...
}
```

### Step 4: Restart
```bash
python start_services.py
# Choose option 2 (vLLM only)

# Monitor logs
tail -f logs/vllm.log
```

## ✅ Option 2 Detailed: Switch to Ollama

Ollama is the most reliable option for RunPod.

### Step 1: Setup Ollama
```bash
# Run setup script
python setup_ollama.py

# This will:
# - Install Ollama
# - Download Typhoon 2.5 model
# - Configure 32k context
# - Start service
```

### Step 2: Update LightRAG Configuration

Edit `lightrag_server.py`:

```python
# Change LLM settings (around line 7-9)
os.environ["LLM_MODEL_NAME"] = "typhoon2-32k"
os.environ["LLM_BASE_URL"] = "http://localhost:11434/v1"
os.environ["LLM_API_KEY"] = "dummy"
```

### Step 3: Start Services Without vLLM
```bash
# Start embedding and reranker
python start_services.py
# Choose option 3 (Embedding + Reranker only)

# In another terminal, start LightRAG
python lightrag_server.py
```

### Step 4: Verify
```bash
# Test Ollama
curl http://localhost:11434/api/tags

# Test LightRAG
curl http://localhost:9621/health
```

## ✅ Option 3 Detailed: Use Transformers

For simplicity, use transformers directly:

### Step 1: Install Dependencies
```bash
pip install transformers accelerate bitsandbytes
```

### Step 2: Create HF LLM Server

Save as `hf_llm_server.py`:

```python
from fastapi import FastAPI
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch
import uvicorn

app = FastAPI()
model = None
tokenizer = None

@app.on_event("startup")
async def load_model():
    global model, tokenizer
    print("Loading Typhoon 2.5...")
    
    tokenizer = AutoTokenizer.from_pretrained("scb10x/typhoon-v2.5-instruct")
    model = AutoModelForCausalLM.from_pretrained(
        "scb10x/typhoon-v2.5-instruct",
        torch_dtype=torch.float16,
        device_map="auto"
    )
    print("✅ Model loaded!")

@app.post("/v1/completions")
async def completions(request: dict):
    prompt = request.get("prompt", "")
    max_tokens = request.get("max_tokens", 512)
    
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    outputs = model.generate(
        **inputs,
        max_new_tokens=max_tokens,
        temperature=0.7,
        do_sample=True
    )
    text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    return {
        "choices": [{
            "text": text,
            "finish_reason": "stop"
        }]
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Step 3: Start
```bash
python hf_llm_server.py
```

## 🎯 Recommended Approach for RunPod

**Use Ollama** - it's the most stable and easiest:

1. ✅ No vLLM compatibility issues
2. ✅ Easy to install and manage
3. ✅ Automatic model management
4. ✅ Good performance
5. ✅ Built-in context window management

## 🐛 Still Having Issues?

### Check PyTorch/CUDA
```bash
python -c "import torch; print(torch.cuda.is_available())"
# Should be True

python -c "import torch; print(torch.version.cuda)"
# Should match your CUDA version
```

### Reinstall PyTorch
```bash
pip uninstall torch torchvision torchaudio -y
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

### Check GPU
```bash
nvidia-smi
# Should show RTX Pro 6000

# Test PyTorch can use it
python -c "import torch; print(torch.cuda.get_device_name(0))"
```

## 💡 Quick Start with Ollama (Recommended)

```bash
# 1. Setup Ollama
python setup_ollama.py

# 2. Edit lightrag_server.py
nano lightrag_server.py
# Change LLM_BASE_URL to http://localhost:11434/v1
# Change LLM_MODEL_NAME to typhoon2-32k

# 3. Start services
python start_services.py
# Choose option 3 (skip vLLM)

# 4. Start LightRAG separately
python lightrag_server.py

# Done! 🎉
```

## 📞 Need More Help?

Check logs for detailed errors:
```bash
tail -f logs/vllm.log
tail -f logs/lightrag.log
```

Or test components individually:
```bash
# Test vLLM directly
python -m vllm.entrypoints.openai.api_server --model scb10x/typhoon-v2.5-instruct --port 8000

# Test Ollama
ollama run typhoon2 "สวัสดี"
```
