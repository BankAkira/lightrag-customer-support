#!/usr/bin/env python3
"""
Embedding Server for LightRAG
Serves BGE-M3 embeddings via FastAPI
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import uvicorn
import torch
from sentence_transformers import SentenceTransformer
import numpy as np

app = FastAPI(title="BGE-M3 Embedding Server")

# Global model instance
model = None
device = None

class EmbeddingRequest(BaseModel):
    input: List[str]
    model: str = "BAAI/bge-m3"

class EmbeddingResponse(BaseModel):
    data: List[dict]
    model: str
    usage: dict

@app.on_event("startup")
async def load_model():
    global model, device
    
    print("🧠 Loading BGE-M3 model...")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"   Device: {device}")
    
    model = SentenceTransformer('BAAI/bge-m3', device=device)
    print("✅ BGE-M3 model loaded!")

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model": "BAAI/bge-m3",
        "device": str(device),
        "ready": model is not None
    }

@app.post("/embeddings")
async def create_embeddings(request: EmbeddingRequest):
    """Create embeddings for input texts"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Generate embeddings
        embeddings = model.encode(
            request.input,
            normalize_embeddings=True,
            batch_size=32,
            show_progress_bar=False
        )
        
        # Format response
        data = []
        for idx, embedding in enumerate(embeddings):
            data.append({
                "object": "embedding",
                "index": idx,
                "embedding": embedding.tolist()
            })
        
        return EmbeddingResponse(
            data=data,
            model=request.model,
            usage={
                "prompt_tokens": sum(len(text.split()) for text in request.input),
                "total_tokens": sum(len(text.split()) for text in request.input)
            }
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/v1/embeddings")
async def create_embeddings_v1(request: EmbeddingRequest):
    """OpenAI-compatible embeddings endpoint"""
    return await create_embeddings(request)

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "BGE-M3 Embedding Server",
        "model": "BAAI/bge-m3",
        "endpoints": {
            "health": "/health",
            "embeddings": "/embeddings or /v1/embeddings"
        }
    }

if __name__ == "__main__":
    print("🚀 Starting BGE-M3 Embedding Server...")
    print("   Port: 8001")
    print("   Model: BAAI/bge-m3")
    print()
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8001,
        log_level="info"
    )
