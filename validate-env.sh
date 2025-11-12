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
