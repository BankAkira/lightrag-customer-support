FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Clone and install LightRAG
RUN git clone https://github.com/HKUDS/LightRAG.git && \
    cd LightRAG && \
    pip install --no-cache-dir -e ".[api]"

# Copy configuration files
COPY .env /app/LightRAG/.env
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose port
EXPOSE 9621

# Set working directory to LightRAG
WORKDIR /app/LightRAG

# Run the server
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["lightrag-server"]
