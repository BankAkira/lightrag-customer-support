#!/usr/bin/env python3
"""
Stop all LightRAG services
"""

import subprocess
import sys

SERVICES = [
    "vllm-server",
    "embedding-server",
    "reranker-server",
    "lightrag-server"
]

def run_command(cmd):
    """Run shell command"""
    subprocess.run(cmd, shell=True, capture_output=True)

def stop_service(session_name):
    """Stop a tmux session"""
    print(f"🛑 Stopping {session_name}...")
    run_command(f"tmux kill-session -t {session_name} 2>/dev/null || true")

def main():
    print("🛑 Stopping all LightRAG services...")
    print("="*60)
    
    for service in SERVICES:
        stop_service(service)
    
    print("="*60)
    print("✅ All services stopped!")
    
    # Check if any sessions remain
    result = subprocess.run(
        "tmux list-sessions 2>/dev/null || echo 'No sessions'",
        shell=True,
        capture_output=True,
        text=True
    )
    
    if "No sessions" not in result.stdout:
        print("\n📋 Remaining tmux sessions:")
        print(result.stdout)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)
