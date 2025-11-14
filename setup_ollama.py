#!/usr/bin/env python3
"""
Alternative LLM Server using Ollama
Use this if vLLM has compatibility issues
"""

import subprocess
import sys
import time
import requests
from pathlib import Path

OLLAMA_URL = "http://localhost:8000"
MODEL_NAME = "typhoon2"

def check_ollama_installed():
    """Check if Ollama is installed"""
    try:
        subprocess.run(["ollama", "--version"], check=True, capture_output=True)
        return True
    except:
        return False

def install_ollama():
    """Install Ollama"""
    print("📦 Installing Ollama...")
    subprocess.run("curl -fsSL https://ollama.com/install.sh | sh", shell=True, check=True)
    time.sleep(2)

def start_ollama_service():
    """Start Ollama service"""
    print("🚀 Starting Ollama service...")
    subprocess.Popen(["ollama", "serve"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(5)

def check_ollama_running():
    """Check if Ollama is running"""
    try:
        response = requests.get(f"{OLLAMA_URL}/api/tags", timeout=2)
        return response.status_code == 200
    except:
        return False

def pull_model():
    """Pull Typhoon model"""
    print(f"📥 Pulling {MODEL_NAME} model (this may take 10-20 minutes)...")
    print("    Model size: ~20GB")
    
    # Pull the model
    result = subprocess.run(
        ["ollama", "pull", MODEL_NAME],
        capture_output=False,
        text=True
    )
    
    if result.returncode == 0:
        print(f"✅ {MODEL_NAME} model downloaded!")
        return True
    else:
        print(f"❌ Failed to download model")
        return False

def create_modelfile():
    """Create custom Modelfile with larger context"""
    print("📝 Creating Modelfile with 32k context...")
    
    modelfile = f"""FROM {MODEL_NAME}

PARAMETER num_ctx 32768
PARAMETER temperature 0.7
PARAMETER top_p 0.9
"""
    
    modelfile_path = Path("/tmp/Modelfile")
    modelfile_path.write_text(modelfile)
    
    # Create custom model
    subprocess.run(
        ["ollama", "create", f"{MODEL_NAME}-32k", "-f", str(modelfile_path)],
        check=True
    )
    
    print(f"✅ Created {MODEL_NAME}-32k with 32k context")

def main():
    print("🎯 Setting up Ollama as LLM Backend")
    print("="*60)
    
    # Check if Ollama is installed
    if not check_ollama_installed():
        print("Ollama not found. Installing...")
        install_ollama()
    else:
        print("✅ Ollama is installed")
    
    # Start Ollama service
    if not check_ollama_running():
        start_ollama_service()
    
    # Wait for service to be ready
    print("⏳ Waiting for Ollama to be ready...")
    for i in range(10):
        if check_ollama_running():
            print("✅ Ollama is running")
            break
        time.sleep(2)
    else:
        print("❌ Ollama failed to start")
        sys.exit(1)
    
    # Check if model exists
    try:
        response = requests.get(f"{OLLAMA_URL}/api/tags")
        models = response.json().get("models", [])
        model_names = [m["name"] for m in models]
        
        if MODEL_NAME not in model_names:
            if not pull_model():
                print("❌ Failed to download model")
                sys.exit(1)
        else:
            print(f"✅ {MODEL_NAME} model already downloaded")
        
        # Create 32k context version
        if f"{MODEL_NAME}-32k" not in model_names:
            create_modelfile()
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
    
    print("\n" + "="*60)
    print("✅ Ollama setup complete!")
    print("="*60)
    print(f"\nModel: {MODEL_NAME}-32k")
    print(f"API: {OLLAMA_URL}")
    print(f"Context: 32k tokens")
    print("\nTo use with LightRAG, update lightrag_server.py:")
    print("  LLM_MODEL_NAME = 'typhoon2-32k'")
    print("  LLM_BASE_URL = 'http://localhost:11434/v1'")
    print("\n💡 Ollama will run as a system service")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)
