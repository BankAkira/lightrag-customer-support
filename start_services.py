#!/usr/bin/env python3
"""
Service Launcher for LightRAG on RunPod
Starts all services in separate tmux sessions
"""

import subprocess
import time
import sys
import os
from pathlib import Path

WORK_DIR = Path("/workspace/lightrag-support")
LOG_DIR = WORK_DIR / "logs"
LOG_DIR.mkdir(exist_ok=True)

SERVICES = {
    "vllm": {
        "name": "vllm-server",
        "command": [
            "python", "-m", "vllm.entrypoints.openai.api_server",
            "--model", "scb10x/typhoon-v2.5-instruct",
            "--host", "0.0.0.0",
            "--port", "8000",
            "--tensor-parallel-size", "1",
            "--gpu-memory-utilization", "0.5",
            "--max-model-len", "32768",
            "--dtype", "auto",
            "--trust-remote-code"
        ],
        "log": "vllm.log",
        "health_url": "http://localhost:8000/health"
    },
    "embedding": {
        "name": "embedding-server",
        "command": [
            "python", "embedding_server.py"
        ],
        "log": "embedding.log",
        "health_url": "http://localhost:8001/health"
    },
    "reranker": {
        "name": "reranker-server",
        "command": [
            "python", "reranker_server.py"
        ],
        "log": "reranker.log",
        "health_url": "http://localhost:8002/health"
    },
    "lightrag": {
        "name": "lightrag-server",
        "command": [
            "python", "lightrag_server.py"
        ],
        "log": "lightrag.log",
        "health_url": "http://localhost:9621/health"
    }
}

def run_command(cmd, capture=False):
    """Run shell command"""
    if capture:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout.strip()
    else:
        subprocess.run(cmd, shell=True)

def check_tmux():
    """Check if tmux is installed"""
    try:
        subprocess.run(["tmux", "-V"], check=True, capture_output=True)
        return True
    except:
        print("❌ tmux is not installed. Installing...")
        run_command("apt-get update && apt-get install -y tmux")
        return True

def kill_session(session_name):
    """Kill tmux session if exists"""
    run_command(f"tmux kill-session -t {session_name} 2>/dev/null || true")

def start_service(service_name, config):
    """Start a service in tmux session"""
    session = config["name"]
    cmd = " ".join(config["command"])
    log_file = LOG_DIR / config["log"]
    
    print(f"🚀 Starting {service_name}...")
    print(f"   Session: {session}")
    print(f"   Log: {log_file}")
    
    # Kill existing session
    kill_session(session)
    
    # Create new tmux session
    tmux_cmd = f"tmux new-session -d -s {session} 'cd {WORK_DIR} && {cmd} 2>&1 | tee {log_file}'"
    run_command(tmux_cmd)
    
    print(f"✅ {service_name} started in tmux session '{session}'")

def check_health(url, max_retries=30, delay=5):
    """Check if service is healthy"""
    import requests
    
    for i in range(max_retries):
        try:
            response = requests.get(url, timeout=2)
            if response.status_code == 200:
                return True
        except:
            pass
        
        if i < max_retries - 1:
            print(f"   Waiting for service... ({i+1}/{max_retries})")
            time.sleep(delay)
    
    return False

def show_status():
    """Show status of all services"""
    print("\n" + "="*60)
    print("📊 Service Status")
    print("="*60)
    
    sessions = run_command("tmux list-sessions -F '#{session_name}' 2>/dev/null || echo ''", capture=True)
    running_sessions = sessions.split('\n') if sessions else []
    
    for service_name, config in SERVICES.items():
        session = config["name"]
        status = "✅ Running" if session in running_sessions else "❌ Stopped"
        print(f"{service_name:15} {status:15} (session: {session})")
    
    print("="*60)

def show_commands():
    """Show useful commands"""
    print("\n" + "="*60)
    print("📝 Useful Commands")
    print("="*60)
    print("View logs:")
    for service_name, config in SERVICES.items():
        print(f"  tail -f {LOG_DIR}/{config['log']}")
    
    print("\nAttach to service:")
    for service_name, config in SERVICES.items():
        print(f"  tmux attach -t {config['name']}")
    
    print("\nStop service:")
    for service_name, config in SERVICES.items():
        print(f"  tmux kill-session -t {config['name']}")
    
    print("\nStop all services:")
    print("  python stop_services.py")
    
    print("\nView all sessions:")
    print("  tmux list-sessions")
    print("="*60)

def main():
    print("🎯 LightRAG Service Launcher for RunPod")
    print("="*60)
    
    # Check prerequisites
    if not check_tmux():
        print("❌ Failed to install tmux")
        sys.exit(1)
    
    # Check if PostgreSQL is running
    try:
        subprocess.run(["pg_isready"], check=True, capture_output=True)
    except:
        print("⚠️  PostgreSQL is not running. Starting...")
        run_command("sudo service postgresql start")
        time.sleep(3)
    
    print("✅ PostgreSQL is running")
    print()
    
    # Ask user which services to start
    print("Which services do you want to start?")
    print("1. All services (recommended)")
    print("2. vLLM only")
    print("3. Embedding + Reranker only")
    print("4. LightRAG only")
    print("5. Custom selection")
    
    choice = input("\nEnter choice (1-5) [1]: ").strip() or "1"
    
    services_to_start = []
    
    if choice == "1":
        services_to_start = list(SERVICES.keys())
    elif choice == "2":
        services_to_start = ["vllm"]
    elif choice == "3":
        services_to_start = ["embedding", "reranker"]
    elif choice == "4":
        services_to_start = ["lightrag"]
    elif choice == "5":
        print("\nAvailable services:")
        for i, name in enumerate(SERVICES.keys(), 1):
            print(f"{i}. {name}")
        selected = input("Enter service numbers (comma-separated): ").strip()
        indices = [int(x.strip())-1 for x in selected.split(",")]
        service_list = list(SERVICES.keys())
        services_to_start = [service_list[i] for i in indices]
    
    print(f"\n🚀 Starting services: {', '.join(services_to_start)}")
    print()
    
    # Start services
    for service_name in services_to_start:
        if service_name in SERVICES:
            start_service(service_name, SERVICES[service_name])
            time.sleep(2)
    
    print("\n⏳ Waiting for services to initialize...")
    time.sleep(5)
    
    # Show status
    show_status()
    
    # Show commands
    show_commands()
    
    print("\n✅ All services started!")
    print("\n💡 Tip: Services run in tmux sessions. They will continue running even if you disconnect.")
    print("        To view logs: tail -f logs/<service>.log")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)
