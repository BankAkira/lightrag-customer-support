#!/usr/bin/env python3
"""
Simple HuggingFace LLM Server for LightRAG
Alternative to vLLM if you have compatibility issues
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import uvicorn
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline
import time

app = FastAPI(title="HuggingFace LLM Server")

# Global model and tokenizer
model = None
tokenizer = None
pipe = None

class CompletionRequest(BaseModel):
    model: str = "scb10x/typhoon-v2.5-instruct"
    prompt: str
    max_tokens: int = 512
    temperature: float = 0.7
    top_p: float = 0.9
    stream: bool = False

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatCompletionRequest(BaseModel):
    model: str = "scb10x/typhoon-v2.5-instruct"
    messages: List[ChatMessage]
    max_tokens: int = 512
    temperature: float = 0.7
    top_p: float = 0.9
    stream: bool = False

@app.on_event("startup")
async def load_model():
    global model, tokenizer, pipe
    
    print("🧠 Loading Typhoon 2.5 model...")
    print("   This may take 2-3 minutes...")
    
    model_name = "scb10x/typhoon-v2.5-instruct"
    
    try:
        # Load tokenizer
        tokenizer = AutoTokenizer.from_pretrained(model_name)
        
        # Load model with GPU
        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            torch_dtype=torch.float16,
            device_map="auto",
            trust_remote_code=True
        )
        
        # Create pipeline for easier generation
        pipe = pipeline(
            "text-generation",
            model=model,
            tokenizer=tokenizer,
            device_map="auto"
        )
        
        print("✅ Model loaded successfully!")
        print(f"   Model: {model_name}")
        print(f"   Device: {model.device}")
        print(f"   Dtype: {model.dtype}")
        
    except Exception as e:
        print(f"❌ Failed to load model: {e}")
        raise

@app.get("/health")
async def health():
    """Health check"""
    return {
        "status": "healthy",
        "model": "scb10x/typhoon-v2.5-instruct",
        "device": str(model.device) if model else "not loaded",
        "ready": model is not None
    }

@app.get("/v1/models")
async def list_models():
    """List available models"""
    return {
        "data": [{
            "id": "scb10x/typhoon-v2.5-instruct",
            "object": "model",
            "created": int(time.time()),
            "owned_by": "scb10x"
        }]
    }

@app.post("/v1/completions")
async def create_completion(request: CompletionRequest):
    """Generate completion"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Generate
        outputs = pipe(
            request.prompt,
            max_new_tokens=request.max_tokens,
            temperature=request.temperature,
            top_p=request.top_p,
            do_sample=True,
            pad_token_id=tokenizer.eos_token_id
        )
        
        generated_text = outputs[0]['generated_text']
        
        # Remove prompt from output
        if generated_text.startswith(request.prompt):
            generated_text = generated_text[len(request.prompt):]
        
        return {
            "id": f"cmpl-{int(time.time())}",
            "object": "text_completion",
            "created": int(time.time()),
            "model": request.model,
            "choices": [{
                "text": generated_text,
                "index": 0,
                "logprobs": None,
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": len(tokenizer.encode(request.prompt)),
                "completion_tokens": len(tokenizer.encode(generated_text)),
                "total_tokens": len(tokenizer.encode(request.prompt)) + len(tokenizer.encode(generated_text))
            }
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/v1/chat/completions")
async def create_chat_completion(request: ChatCompletionRequest):
    """Generate chat completion"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Convert messages to prompt
        prompt = ""
        for msg in request.messages:
            if msg.role == "system":
                prompt += f"System: {msg.content}\n\n"
            elif msg.role == "user":
                prompt += f"User: {msg.content}\n\n"
            elif msg.role == "assistant":
                prompt += f"Assistant: {msg.content}\n\n"
        
        prompt += "Assistant: "
        
        # Generate
        outputs = pipe(
            prompt,
            max_new_tokens=request.max_tokens,
            temperature=request.temperature,
            top_p=request.top_p,
            do_sample=True,
            pad_token_id=tokenizer.eos_token_id
        )
        
        generated_text = outputs[0]['generated_text']
        
        # Extract only the assistant's response
        if generated_text.startswith(prompt):
            generated_text = generated_text[len(prompt):]
        
        return {
            "id": f"chatcmpl-{int(time.time())}",
            "object": "chat.completion",
            "created": int(time.time()),
            "model": request.model,
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": generated_text
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": len(tokenizer.encode(prompt)),
                "completion_tokens": len(tokenizer.encode(generated_text)),
                "total_tokens": len(tokenizer.encode(prompt)) + len(tokenizer.encode(generated_text))
            }
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "HuggingFace LLM Server",
        "model": "scb10x/typhoon-v2.5-instruct",
        "endpoints": {
            "health": "/health",
            "models": "/v1/models",
            "completions": "/v1/completions",
            "chat": "/v1/chat/completions"
        }
    }

if __name__ == "__main__":
    print("🚀 Starting HuggingFace LLM Server...")
    print("   Port: 8000")
    print("   Model: scb10x/typhoon-v2.5-instruct")
    print("   Compatible with OpenAI API format")
    print()
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
