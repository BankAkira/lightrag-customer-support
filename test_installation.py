#!/usr/bin/env python3
"""
Test LightRAG Installation
Verify all components are properly installed
"""

import sys

def test_import(module_name, package_name=None):
    """Test if a module can be imported"""
    try:
        __import__(module_name)
        print(f"✅ {module_name}")
        return True
    except ImportError as e:
        print(f"❌ {module_name} - {e}")
        if package_name:
            print(f"   Install with: pip install {package_name}")
        return False

def main():
    print("🔍 Testing LightRAG Installation")
    print("="*60)
    
    all_ok = True
    
    # Test core dependencies
    print("\n📦 Core Dependencies:")
    all_ok &= test_import("torch")
    all_ok &= test_import("transformers")
    all_ok &= test_import("sentence_transformers", "sentence-transformers")
    all_ok &= test_import("FlagEmbedding", "FlagEmbedding")
    all_ok &= test_import("fastapi")
    all_ok &= test_import("uvicorn")
    all_ok &= test_import("psycopg2", "psycopg2-binary")
    all_ok &= test_import("asyncpg")
    
    # Test LightRAG
    print("\n🔦 LightRAG:")
    lightrag_ok = test_import("lightrag")
    all_ok &= lightrag_ok
    
    if lightrag_ok:
        try:
            import lightrag
            print(f"   Version: {lightrag.__version__ if hasattr(lightrag, '__version__') else 'unknown'}")
            print(f"   Path: {lightrag.__file__}")
        except:
            pass
    else:
        print("\n   💡 To install LightRAG:")
        print("   cd /workspace/lightrag-support")
        print("   git clone https://github.com/HKUDS/LightRAG.git")
        print("   cd LightRAG && pip install -e .[api]")
    
    # Test lightrag-server command
    print("\n🌐 LightRAG Server Command:")
    import subprocess
    try:
        result = subprocess.run(
            ["which", "lightrag-server"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            print(f"✅ lightrag-server found at: {result.stdout.strip()}")
        else:
            print("❌ lightrag-server command not found")
            print("   This should be installed with: pip install -e LightRAG/[api]")
            all_ok = False
    except Exception as e:
        print(f"❌ Error checking command: {e}")
        all_ok = False
    
    # Test GPU
    print("\n🎮 GPU:")
    try:
        import torch
        if torch.cuda.is_available():
            print(f"✅ CUDA available: {torch.cuda.get_device_name(0)}")
            print(f"   CUDA version: {torch.version.cuda}")
            print(f"   GPU memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")
        else:
            print("⚠️  CUDA not available")
    except Exception as e:
        print(f"❌ Error checking GPU: {e}")
    
    # Test PostgreSQL
    print("\n🗄️  PostgreSQL:")
    try:
        import subprocess
        result = subprocess.run(
            ["pg_isready", "-h", "localhost"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            print("✅ PostgreSQL is running")
        else:
            print("❌ PostgreSQL is not running")
            print("   Start with: sudo service postgresql start")
            all_ok = False
    except Exception as e:
        print(f"❌ Error checking PostgreSQL: {e}")
    
    # Summary
    print("\n" + "="*60)
    if all_ok:
        print("✅ All checks passed! You're ready to start services.")
    else:
        print("⚠️  Some components need attention. See errors above.")
    print("="*60)

if __name__ == "__main__":
    main()
