# 🤖 LightRAG Customer Support System

AI-powered customer support system using LightRAG with Thai + English language support, optimized for RunPod RTX Pro 6000.

## ✨ Features

- 🌏 **Multilingual Support**: Thai and English (easily extensible)
- ⚡ **Fast Response**: GPU-accelerated with vLLM
- 🧠 **Smart RAG**: Knowledge graph + vector retrieval
- 📚 **Multi-format Docs**: PDF, DOCX, TXT, and more
- 🔄 **Real-time Updates**: Dynamic document indexing
- 🎯 **Context-aware**: Maintains conversation history
- 🚀 **Production Ready**: Docker Compose deployment

## 🏗️ Architecture

```
┌─────────────────┐
│   Customer      │
│   Questions     │
└────────┬────────┘
         │
         v
┌─────────────────┐
│  LightRAG API   │
│  (Port 9621)    │
└────────┬────────┘
         │
    ┌────┴─────┬──────────┬───────────┐
    │          │          │           │
    v          v          v           v
┌────────┐ ┌──────┐ ┌─────────┐ ┌──────────┐
│ vLLM   │ │ BGE  │ │  BGE    │ │PostgreSQL│
│Typhoon │ │ M3   │ │Reranker │ │  +       │
│  2.5   │ │Embed │ │         │ │ pgvector │
└────────┘ └──────┘ └─────────┘ └──────────┘
```

## 🚀 Quick Start

### Prerequisites
- RunPod instance with RTX Pro 6000 (96GB VRAM)
- Docker & Docker Compose
- NVIDIA Docker runtime

### 1. Clone or Upload Files
```bash
# On your RunPod instance
cd /workspace
mkdir lightrag-support && cd lightrag-support

# Upload these files:
# - docker-compose.yml
# - Dockerfile
# - .env
# - entrypoint.sh
```

### 2. Configure Environment
```bash
# Edit .env file
nano .env

# Important settings:
# - POSTGRES_PASSWORD (change from default!)
# - LANGUAGE=Thai and English
# - WORKSPACE=customer_support
```

### 3. Deploy
```bash
# Make scripts executable
chmod +x entrypoint.sh

# Start all services
docker-compose up -d

# Watch logs (first run takes 5-10 mins to download models)
docker-compose logs -f
```

### 4. Verify
```bash
# Check all services are running
docker-compose ps

# Test health
curl http://localhost:9621/health
curl http://localhost:8000/health   # vLLM
curl http://localhost:8001/health   # Embedding
```

### 5. Index Your Documents
```python
from api_client_example import CustomerSupportRAG

client = CustomerSupportRAG("http://localhost:9621")

# Index your product documentation
docs = [
    "Your Thai documentation here...",
    "Your English documentation here..."
]

client.index_documents(docs)
```

### 6. Query!
```python
# Ask questions in Thai
answer = client.query("ราคาสินค้าเท่าไหร่?", mode="hybrid")
print(answer['response'])

# Or in English
answer = client.query("How to install the product?", mode="hybrid")
print(answer['response'])
```

## 📖 Full Documentation

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions including:
- Complete GPU configuration
- Performance tuning for RTX Pro 6000
- Production deployment checklist
- Troubleshooting guide
- Security best practices

## 🎯 Query Modes

LightRAG supports different retrieval modes:

- **`hybrid`** (Recommended): Combines local + global search
- **`mix`**: Knowledge graph + vector search (best with reranker)
- **`local`**: Context-dependent information
- **`global`**: Global knowledge summary
- **`naive`**: Simple vector search

```python
# Example with different modes
answer = client.query("question", mode="hybrid")  # Best for most cases
answer = client.query("question", mode="mix")     # Best with reranker enabled
```

## 🔧 Configuration

### GPU Memory Tuning

Edit `docker-compose.yml`:

```yaml
vllm:
  command: >
    --model scb10x/typhoon-v2.5-instruct
    --gpu-memory-utilization 0.5  # Adjust 0.3-0.7
    --max-model-len 32768          # Context length
```

### Storage Options

Currently configured with PostgreSQL for production use:
- `PGKVStorage`: Document and chunk storage
- `PGVectorStorage`: Embeddings with pgvector
- `PGGraphStorage`: Knowledge graph
- `PGDocStatusStorage`: Processing status

### Language Configuration

Edit `.env`:
```bash
LANGUAGE=Thai and English
ENTITY_TYPES=["organization", "person", "product", "service"]
```

## 📊 Performance

On RTX Pro 6000 (96GB VRAM):
- **Model Loading**: ~2-3 minutes (first time)
- **Document Indexing**: ~10-30 seconds per document
- **Query Response**: ~2-5 seconds (hybrid mode)
- **Concurrent Users**: 10-20+ (with proper tuning)

## 🐳 Services

| Service | Port | Purpose | GPU |
|---------|------|---------|-----|
| LightRAG Server | 9621 | Main API & Web UI | - |
| vLLM (Typhoon 2.5) | 8000 | LLM inference | ✅ |
| BGE-M3 Embedding | 8001 | Text embeddings | ✅ |
| BGE Reranker | 8002 | Result reranking | ✅ |
| PostgreSQL | 5432 | Data storage | - |

## 🔐 Security Notes

**Before Production:**
1. Change `POSTGRES_PASSWORD` in `.env`
2. Enable API authentication
3. Setup SSL/TLS (use nginx/Caddy)
4. Configure firewall rules
5. Regular backups of PostgreSQL

## 🛠️ Troubleshooting

**GPU not detected?**
```bash
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

**Out of memory?**
```yaml
# Reduce in docker-compose.yml:
--gpu-memory-utilization 0.3
```

**Slow responses?**
```bash
# Check GPU usage
nvidia-smi

# Monitor logs
docker-compose logs -f vllm
```

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for complete troubleshooting.

## 📦 Files Included

```
.
├── docker-compose.yml          # Main deployment config
├── Dockerfile                  # LightRAG server image
├── .env                       # Environment variables
├── entrypoint.sh              # Startup script
├── api_client_example.py      # Python API client
├── DEPLOYMENT_GUIDE.md        # Full deployment guide
└── README.md                  # This file
```

## 🤝 API Endpoints

### Index Documents
```bash
POST /v1/documents/index
{
  "documents": ["text1", "text2"],
  "doc_ids": ["id1", "id2"]
}
```

### Query
```bash
POST /v1/query
{
  "query": "Your question in Thai or English",
  "mode": "hybrid",
  "enable_rerank": true
}
```

### Health Check
```bash
GET /health
```

See API documentation at `http://localhost:9621/docs` when server is running.

## 🎓 Learn More

- [LightRAG GitHub](https://github.com/HKUDS/LightRAG)
- [Typhoon 2.5 Model](https://huggingface.co/scb10x/typhoon-v2.5-instruct)
- [BGE-M3 Embeddings](https://huggingface.co/BAAI/bge-m3)
- [vLLM Documentation](https://docs.vllm.ai/)

## 📝 License

This implementation uses:
- LightRAG (MIT License)
- vLLM (Apache 2.0)
- Typhoon 2.5 (Check model license)
- BGE Models (MIT License)

## 🙋 Support

Need help? Check the [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) or review logs:
```bash
docker-compose logs -f [service_name]
```

---

Built with ❤️ for Thai businesses using LightRAG + Typhoon 2.5
