# 🔧 Fix for pgvector Installation Issue

If you get the error: `extension "vector" is not available`, use this fixed setup script.

## Quick Fix

Run this instead of the original `setup_postgres.sh`:

```bash
bash setup_postgres_fixed.sh
```

## What It Does

1. **Tries apt install first** - fastest if available
2. **Falls back to building from source** - if apt fails
3. **Installs all dependencies** - build-essential, postgresql-dev
4. **Builds pgvector 0.7.4** - from official GitHub repo
5. **Sets up database** - creates user and enables extension

## Manual Fix (If Script Fails)

### Option 1: Build pgvector from Source

```bash
# Install dependencies
apt-get update
apt-get install -y build-essential postgresql-server-dev-16 git

# Clone and build pgvector
cd /tmp
git clone --branch v0.7.4 https://github.com/pgvector/pgvector.git
cd pgvector
make
sudo make install

# Verify installation
ls -la /usr/share/postgresql/16/extension/vector*

# Now run the database setup again
bash setup_postgres.sh
```

### Option 2: Use Different PostgreSQL Version

```bash
# Check your PostgreSQL version
psql --version

# If you have PostgreSQL 14 or 15, install matching pgvector:
apt-get install -y postgresql-14-pgvector  # for PG 14
apt-get install -y postgresql-15-pgvector  # for PG 15
```

### Option 3: Alternative Storage (Without pgvector)

If pgvector installation keeps failing, you can use alternative storage:

Edit `lightrag_server.py` and change:

```python
# Instead of PostgreSQL with pgvector
os.environ["VECTOR_STORAGE"] = "PGVectorStorage"

# Use one of these alternatives:
os.environ["VECTOR_STORAGE"] = "NanoVectorDBStorage"  # File-based
# or
os.environ["VECTOR_STORAGE"] = "FaissVectorDBStorage"  # Facebook's FAISS

# Keep other PostgreSQL storage as is
os.environ["KV_STORAGE"] = "PGKVStorage"
os.environ["GRAPH_STORAGE"] = "PGGraphStorage"
```

Then install FAISS:
```bash
pip install faiss-gpu  # For GPU version
# or
pip install faiss-cpu  # For CPU version
```

## Verify Installation

After running the fixed script, verify pgvector is installed:

```bash
sudo -u postgres psql -d lightrag -c "SELECT * FROM pg_extension WHERE extname = 'vector';"

# Should show:
#  extname | extowner | extnamespace | extrelocatable | extversion 
# ---------+----------+--------------+----------------+------------
#  vector  |       10 |         2200 | t              | 0.7.4
```

## Common Issues

### Issue: postgresql-server-dev-16 not found

```bash
# Check PostgreSQL version
psql --version

# Install matching dev package
apt-get install -y postgresql-server-dev-$(psql --version | grep -oP '\d+')
```

### Issue: Build fails with "make: command not found"

```bash
apt-get install -y build-essential
```

### Issue: Permission denied during make install

```bash
sudo make install
```

## Test Database Connection

After setup, test the connection:

```bash
psql -h localhost -U lightrag -d lightrag -c "\dx"

# Enter password: lightrag_secure_password_2024
# Should show vector extension in the list
```

## Still Having Issues?

If pgvector keeps failing, the best alternative is to use **NanoVectorDBStorage** (file-based):

1. Edit `lightrag_server.py`:
   ```python
   os.environ["VECTOR_STORAGE"] = "NanoVectorDBStorage"
   ```

2. This uses local files instead of PostgreSQL for vectors
3. Still uses PostgreSQL for other data
4. Simpler, no extension needed
5. Works great for development and small-to-medium deployments

## Need Help?

Check logs to see exact error:
```bash
cat /var/log/postgresql/postgresql-16-main.log
```

Or check PostgreSQL service status:
```bash
sudo service postgresql status
```
