#!/bin/bash

# Prerequisites check script for infra-global setup

echo "🔍 Checking prerequisites for infra-global setup..."
echo ""

ERRORS=0

# Check Azure CLI
echo -n "Checking Azure CLI... "
if command -v az &> /dev/null; then
    AZ_VERSION=$(az --version | head -n 1)
    echo "✅ Found: $AZ_VERSION"
    
    # Check if logged in
    echo -n "  Checking Azure login... "
    if az account show &> /dev/null; then
        ACCOUNT=$(az account show --query name -o tsv)
        echo "✅ Logged in as: $ACCOUNT"
    else
        echo "❌ Not logged in. Run: az login"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ Not found. Install from: https://aka.ms/InstallAzureCLI"
    ERRORS=$((ERRORS + 1))
fi

# Check Terraform
echo -n "Checking Terraform... "
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Found: v$TF_VERSION"
    
    # Check version >= 1.0
    MAJOR_VERSION=$(echo $TF_VERSION | cut -d. -f1)
    if [ "$MAJOR_VERSION" -ge 1 ]; then
        echo "  ✅ Version is >= 1.0"
    else
        echo "  ⚠️  Version should be >= 1.0"
    fi
else
    echo "❌ Not found. Install from: https://www.terraform.io/downloads"
    ERRORS=$((ERRORS + 1))
fi

# Check Git
echo -n "Checking Git... "
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    echo "✅ Found: $GIT_VERSION"
else
    echo "❌ Not found. Install from: https://git-scm.com/downloads"
    ERRORS=$((ERRORS + 1))
fi

# Check GitHub CLI (optional)
echo -n "Checking GitHub CLI (optional)... "
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -n 1 | cut -d' ' -f3)
    echo "✅ Found: $GH_VERSION"
    
    # Check if logged in
    echo -n "  Checking GitHub login... "
    if gh auth status &> /dev/null; then
        echo "✅ Logged in"
    else
        echo "⚠️  Not logged in. Run: gh auth login"
    fi
else
    echo "⚠️  Not found (optional). Install from: https://cli.github.com/"
fi

# Check OpenSSL (for random name generation)
echo -n "Checking OpenSSL... "
if command -v openssl &> /dev/null; then
    echo "✅ Found"
else
    echo "⚠️  Not found (needed for setup script)"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ All required prerequisites are met!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Run: ./setup-backend.sh (to create Azure Storage account)"
    echo "   2. Copy terraform.tfvars.example to terraform.tfvars and configure"
    echo "   3. Run: terraform init"
    echo "   4. Run: terraform plan"
    echo "   5. Run: terraform apply"
else
    echo "❌ Some prerequisites are missing. Please install them first."
    exit 1
fi

