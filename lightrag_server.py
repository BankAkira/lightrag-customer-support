#!/usr/bin/env python3
"""
LightRAG Server Wrapper
Configures and starts LightRAG server with custom settings
"""

import os
import sys

# Set environment variables before importing LightRAG
os.environ["LLM_MODEL_NAME"] = "scb10x/typhoon-v2.5-instruct"
os.environ["LLM_BASE_URL"] = "http://localhost:8000/v1"
os.environ["LLM_API_KEY"] = "dummy"
os.environ["LLM_MAX_TOKENS"] = "32768"

os.environ["EMBEDDING_MODEL"] = "BAAI/bge-m3"
os.environ["EMBEDDING_BASE_URL"] = "http://localhost:8001"
os.environ["EMBEDDING_DIM"] = "1024"

os.environ["RERANKER_MODEL"] = "BAAI/bge-reranker-v2-m3"
os.environ["RERANKER_BASE_URL"] = "http://localhost:8002"
os.environ["ENABLE_RERANK"] = "true"

os.environ["KV_STORAGE"] = "PGKVStorage"
os.environ["VECTOR_STORAGE"] = "PGVectorStorage"
os.environ["GRAPH_STORAGE"] = "PGGraphStorage"
os.environ["DOC_STATUS_STORAGE"] = "PGDocStatusStorage"

os.environ["POSTGRES_HOST"] = "localhost"
os.environ["POSTGRES_PORT"] = "5432"
os.environ["POSTGRES_USER"] = "lightrag"
os.environ["POSTGRES_PASSWORD"] = "lightrag_secure_password_2024"
os.environ["POSTGRES_DATABASE"] = "lightrag"

os.environ["WORKING_DIR"] = "/workspace/lightrag-support/lightrag_data"
os.environ["WORKSPACE"] = "customer_support"

os.environ["LANGUAGE"] = "Thai and English"
os.environ["ENTITY_TYPES"] = '["organization", "person", "product", "service", "location", "event", "issue", "feature"]'

os.environ["HOST"] = "0.0.0.0"
os.environ["PORT"] = "9621"

# Now import and run LightRAG server
try:
    # Create working directory if doesn't exist
    os.makedirs(os.environ["WORKING_DIR"], exist_ok=True)
    
    print("🚀 Starting LightRAG Server...")
    print(f"   Working Directory: {os.environ['WORKING_DIR']}")
    print(f"   Workspace: {os.environ['WORKSPACE']}")
    print(f"   Language: {os.environ['LANGUAGE']}")
    print(f"   Port: {os.environ['PORT']}")
    print()
    
    # Import and run the LightRAG server
    from lightrag.server import start_server
    start_server()
    
except ImportError as e:
    print(f"❌ Failed to import LightRAG server: {e}")
    print("   Make sure LightRAG is installed: pip install -e LightRAG/")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error starting LightRAG server: {e}")
    sys.exit(1)
