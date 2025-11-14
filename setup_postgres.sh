#!/bin/bash
# PostgreSQL Setup Script for LightRAG

set -e

echo "🗄️ Setting up PostgreSQL for LightRAG..."

# Install pgvector extension
echo "📦 Installing pgvector extension..."
apt-get update
apt-get install -y postgresql-16-pgvector || apt-get install -y postgresql-pgvector

# Start PostgreSQL service
echo "Starting PostgreSQL service..."
sudo service postgresql start

# Wait for PostgreSQL to be ready
sleep 3

# Create database and user
sudo -u postgres psql << EOF
-- Create database
CREATE DATABASE lightrag;

-- Create user
CREATE USER lightrag WITH PASSWORD 'lightrag_secure_password_2024';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE lightrag TO lightrag;

-- Connect to lightrag database
\c lightrag

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO lightrag;

-- Show confirmation
\l
EOF

echo "✅ PostgreSQL setup complete!"
echo ""
echo "Database: lightrag"
echo "User: lightrag"
echo "Password: lightrag_secure_password_2024"
echo ""
echo "⚠️  IMPORTANT: Change the password in production!"
echo "   Run: sudo -u postgres psql -c \"ALTER USER lightrag PASSWORD 'your_new_password';\""
