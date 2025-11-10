#!/bin/bash

# Install prerequisites for infra-global setup

set -e

echo "📦 Installing prerequisites..."
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install from: https://brew.sh"
    exit 1
fi

# Install Azure CLI
echo "📦 Installing Azure CLI..."
if command -v az &> /dev/null; then
    echo "✅ Azure CLI already installed"
else
    brew install azure-cli
    echo "✅ Azure CLI installed"
fi

# Install Terraform
echo "📦 Installing Terraform..."
if command -v terraform &> /dev/null; then
    echo "✅ Terraform already installed"
else
    brew install terraform
    echo "✅ Terraform installed"
fi

# Install GitHub CLI (optional but recommended)
echo "📦 Installing GitHub CLI (optional)..."
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI already installed"
else
    brew install gh
    echo "✅ GitHub CLI installed"
fi

echo ""
echo "✅ Prerequisites installation complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Authenticate with Azure: az login"
echo "   2. Authenticate with GitHub: gh auth login"
echo "   3. Run: ./check-prerequisites.sh (to verify installation)"
echo "   4. Run: ./setup-backend.sh (to create Azure Storage account)"

