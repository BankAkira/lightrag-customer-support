#!/usr/bin/env python3
"""
Reranker Server for LightRAG
Serves BGE Reranker V2 M3 via FastAPI
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Tuple
import uvicorn
import torch
from FlagEmbedding import FlagReranker

app = FastAPI(title="BGE Reranker Server")

# Global reranker instance
reranker = None
device = None

class RerankRequest(BaseModel):
    query: str
    documents: List[str]
    top_n: int = 5

class RerankResponse(BaseModel):
    results: List[dict]
    model: str

@app.on_event("startup")
async def load_model():
    global reranker, device
    
    print("🧠 Loading BGE Reranker V2 M3 model...")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"   Device: {device}")
    
    reranker = FlagReranker(
        'BAAI/bge-reranker-v2-m3',
        use_fp16=True if device == "cuda" else False
    )
    print("✅ BGE Reranker V2 M3 model loaded!")

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model": "BAAI/bge-reranker-v2-m3",
        "device": str(device),
        "ready": reranker is not None
    }

@app.post("/rerank")
async def rerank(request: RerankRequest):
    """Rerank documents based on query relevance"""
    if reranker is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Create query-document pairs
        pairs = [[request.query, doc] for doc in request.documents]
        
        # Compute relevance scores
        scores = reranker.compute_score(pairs, normalize=True)
        
        # Handle single score vs list of scores
        if isinstance(scores, (int, float)):
            scores = [scores]
        
        # Sort by scores (descending)
        doc_score_pairs = list(zip(request.documents, scores))
        doc_score_pairs.sort(key=lambda x: x[1], reverse=True)
        
        # Return top_n results
        results = []
        for idx, (doc, score) in enumerate(doc_score_pairs[:request.top_n]):
            results.append({
                "index": idx,
                "document": doc,
                "relevance_score": float(score)
            })
        
        return RerankResponse(
            results=results,
            model="BAAI/bge-reranker-v2-m3"
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/v1/rerank")
async def rerank_v1(request: RerankRequest):
    """OpenAI-compatible rerank endpoint"""
    return await rerank(request)

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "BGE Reranker V2 M3 Server",
        "model": "BAAI/bge-reranker-v2-m3",
        "endpoints": {
            "health": "/health",
            "rerank": "/rerank or /v1/rerank"
        }
    }

if __name__ == "__main__":
    print("🚀 Starting BGE Reranker Server...")
    print("   Port: 8002")
    print("   Model: BAAI/bge-reranker-v2-m3")
    print()
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8002,
        log_level="info"
    )
