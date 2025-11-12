# .env File Troubleshooting Guide

Common issues with the `.env` file and how to fix them.

## ❌ Error: "and: command not found"

### Problem
```bash
deploy-runpod.sh: line 39: and: command not found
```

### Cause
Values with spaces in the `.env` file are not quoted.

### Example of WRONG configuration:
```bash
LANGUAGE=Thai and English
```

### ✅ Correct configuration:
```bash
LANGUAGE="Thai and English"
```

### How to Fix
1. Open your `.env` file:
   ```bash
   nano .env
   ```

2. Find the line with `LANGUAGE=` and add quotes:
   ```bash
   # Before:
   LANGUAGE=Thai and English

   # After:
   LANGUAGE="Thai and English"
   ```

3. Same for ENTITY_TYPES - use single quotes:
   ```bash
   # Before:
   ENTITY_TYPES=["organization", "person", ...]

   # After:
   ENTITY_TYPES='["organization", "person", ...]'
   ```

4. Save and validate:
   ```bash
   bash validate-env.sh
   ```

## ❌ Error: "export: not a valid identifier"

### Problem
```bash
deploy-runpod.sh: line 12: export: 'person,': not a valid identifier
```

### Cause
JSON arrays or values with special characters are not properly quoted.

### ✅ Solution
Always use single quotes around JSON arrays:
```bash
ENTITY_TYPES='["organization", "person", "product"]'
```

## 🔐 Warning: Using Default Password

### Problem
You're using the default password which is insecure.

### Default passwords to avoid:
- `CHANGE_ME_BEFORE_PRODUCTION`
- `lightrag_password_change_me`

### ✅ Solution
Set a strong password in `.env`:
```bash
POSTGRES_PASSWORD="your_secure_random_password_here_123!"
```

Generate a random password:
```bash
# Option 1: Using openssl
openssl rand -base64 32

# Option 2: Using /dev/urandom
tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo
```

## 📋 .env File Checklist

Before deploying, check your `.env` file:

- [ ] File exists (created from `.env.example`)
- [ ] `POSTGRES_PASSWORD` is changed from default
- [ ] `LANGUAGE` value is quoted: `LANGUAGE="Thai and English"`
- [ ] `ENTITY_TYPES` is quoted with single quotes: `ENTITY_TYPES='[...]'`
- [ ] No unquoted values with spaces
- [ ] No missing closing quotes
- [ ] Run `bash validate-env.sh` successfully

## 🧪 Test Your Configuration

Always validate before deploying:

```bash
# Validate .env file
bash validate-env.sh

# If validation passes, deploy:
bash deploy-runpod.sh
```

## 📝 Correct .env Example

```bash
# PostgreSQL Configuration
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=lightrag
POSTGRES_PASSWORD="my_very_secure_password_123!"  # Quoted!
POSTGRES_DATABASE=lightrag

# Language Configuration
LANGUAGE="Thai and English"  # Quoted because of space!

# Entity Types - Single quotes around JSON array
ENTITY_TYPES='["organization", "person", "product", "service"]'
```

## 🆘 Still Having Issues?

1. **Recreate from template:**
   ```bash
   mv .env .env.backup
   cp .env.example .env
   nano .env  # Edit with correct values
   ```

2. **Check for hidden characters:**
   ```bash
   cat -A .env  # Shows all characters including hidden ones
   ```

3. **Validate before deploying:**
   ```bash
   bash validate-env.sh
   ```

4. **Check syntax errors:**
   ```bash
   # This should load without errors:
   set -a
   source .env
   set +a
   echo "✅ .env loaded successfully"
   ```

## 💡 Best Practices

1. **Always quote values with:**
   - Spaces: `LANGUAGE="Thai and English"`
   - Special characters: `PASSWORD="p@ssw0rd!123"`
   - JSON/Arrays: `TYPES='["a", "b", "c"]'`

2. **Use the validation script:**
   ```bash
   bash validate-env.sh
   ```

3. **Keep a backup:**
   ```bash
   cp .env .env.backup
   ```

4. **Never commit .env to git**
   - It's in `.gitignore`
   - Only commit `.env.example`

## 🔄 Quick Fix Commands

```bash
# Fix LANGUAGE value
sed -i 's/LANGUAGE=Thai and English/LANGUAGE="Thai and English"/g' .env

# Fix ENTITY_TYPES value
sed -i 's/ENTITY_TYPES=\[/ENTITY_TYPES='"'"'[/g' .env
sed -i 's/\]$/]'"'"'/g' .env

# Validate
bash validate-env.sh
```
