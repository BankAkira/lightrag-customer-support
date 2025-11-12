#!/bin/bash
# Validate .env file before deployment

echo "🔍 Validating .env file..."
echo ""

if [ ! -f .env ]; then
    echo "❌ ERROR: .env file not found!"
    echo ""
    echo "Please create it from the template:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Check for common syntax issues
echo "🔍 Checking for common syntax issues..."
if grep -q "LANGUAGE=Thai and English" .env 2>/dev/null; then
    echo "❌ ERROR: LANGUAGE value is not quoted!"
    echo "   Found: LANGUAGE=Thai and English"
    echo "   Should be: LANGUAGE=\"Thai and English\""
    echo ""
    echo "This will cause a 'and: command not found' error."
    echo "Please add quotes around values with spaces."
    exit 1
fi

if grep -q 'ENTITY_TYPES=\[' .env 2>/dev/null; then
    if ! grep -q "ENTITY_TYPES='" .env 2>/dev/null; then
        echo "⚠️  WARNING: ENTITY_TYPES should be quoted with single quotes"
        echo "   Example: ENTITY_TYPES='[\"organization\", \"person\", ...]'"
    fi
fi

# Test loading the .env file
echo "📋 Testing environment variable loading..."

set -a
source <(grep -v '^#' .env | grep -v '^$') 2>/dev/null
EXIT_CODE=$?
set +a

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ ERROR: Failed to load .env file"
    echo ""
    echo "Common issues:"
    echo "  - Unquoted values with special characters"
    echo "  - Missing closing quotes"
    echo "  - Invalid syntax"
    echo ""
    echo "Please check your .env file for syntax errors"
    exit 1
fi

echo "✅ .env file loaded successfully!"
echo ""

# Check critical variables
echo "🔐 Checking critical variables..."
ERRORS=0

# Check POSTGRES_PASSWORD
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "❌ POSTGRES_PASSWORD is not set"
    ERRORS=$((ERRORS + 1))
elif [ "$POSTGRES_PASSWORD" = "CHANGE_ME_BEFORE_PRODUCTION" ]; then
    echo "⚠️  WARNING: POSTGRES_PASSWORD is still set to default!"
    echo "   Please change it to a secure password before production deployment"
elif [ "$POSTGRES_PASSWORD" = "lightrag_password_change_me" ]; then
    echo "⚠️  WARNING: POSTGRES_PASSWORD is still set to default!"
    echo "   Please change it to a secure password before production deployment"
else
    echo "✅ POSTGRES_PASSWORD is set"
fi

# Check POSTGRES_USER
if [ -z "$POSTGRES_USER" ]; then
    echo "⚠️  POSTGRES_USER is not set, will use default: lightrag"
else
    echo "✅ POSTGRES_USER is set: ${POSTGRES_USER}"
fi

# Check POSTGRES_DATABASE
if [ -z "$POSTGRES_DATABASE" ]; then
    echo "⚠️  POSTGRES_DATABASE is not set, will use default: lightrag"
else
    echo "✅ POSTGRES_DATABASE is set: ${POSTGRES_DATABASE}"
fi

# Check ENTITY_TYPES
if [ -z "$ENTITY_TYPES" ]; then
    echo "⚠️  ENTITY_TYPES is not set, will use default"
else
    echo "✅ ENTITY_TYPES is set"
fi

echo ""

if [ $ERRORS -gt 0 ]; then
    echo "❌ Found $ERRORS error(s). Please fix them before deploying."
    exit 1
else
    echo "✅ Validation passed!"
    echo ""
    echo "You can now deploy with:"
    echo "  bash deploy-runpod.sh"
fi
