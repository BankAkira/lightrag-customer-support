#!/bin/bash
# PostgreSQL Setup Script for LightRAG with pgvector from source

set -e

echo "🗄️ Setting up PostgreSQL for LightRAG..."

# Install build dependencies
echo "📦 Installing build dependencies..."
apt-get update
apt-get install -y build-essential postgresql-server-dev-16 git

# Try to install pgvector from apt first
echo "📦 Trying to install pgvector from apt..."
if apt-get install -y postgresql-16-pgvector 2>/dev/null; then
    echo "✅ pgvector installed from apt"
else
    echo "⚠️  apt package not available, building from source..."
    
    # Clone and build pgvector from source
    cd /tmp
    git clone --branch v0.7.4 https://github.com/pgvector/pgvector.git
    cd pgvector
    make
    make install
    cd /
    rm -rf /tmp/pgvector
    
    echo "✅ pgvector built and installed from source"
fi

# Start PostgreSQL service
echo "🚀 Starting PostgreSQL service..."
sudo service postgresql start

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 5

# Create database and user
echo "👤 Creating database and user..."
sudo -u postgres psql << EOF
-- Create database
DROP DATABASE IF EXISTS lightrag;
CREATE DATABASE lightrag;

-- Create user
DROP USER IF EXISTS lightrag;
CREATE USER lightrag WITH PASSWORD 'lightrag_secure_password_2024';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE lightrag TO lightrag;

-- Connect to lightrag database
\c lightrag

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO lightrag;

-- Verify extension is installed
SELECT * FROM pg_extension WHERE extname = 'vector';

EOF

echo "✅ PostgreSQL setup complete!"
echo ""
echo "📊 Database Configuration:"
echo "   Database: lightrag"
echo "   User: lightrag"
echo "   Password: lightrag_secure_password_2024"
echo "   Host: localhost"
echo "   Port: 5432"
echo ""
echo "⚠️  IMPORTANT: Change the password in production!"
echo "   Run: sudo -u postgres psql -c \"ALTER USER lightrag PASSWORD 'your_new_password';\""
echo ""
echo "🔍 Verify connection:"
echo "   psql -h localhost -U lightrag -d lightrag -c \"SELECT version();\""
