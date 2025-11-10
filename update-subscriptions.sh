#!/bin/bash

# Script to update terraform.tfvars with subscription IDs
# Run this after creating subscriptions in Azure Portal

set -e

echo "🔍 Looking for Pravenya subscriptions..."

# Get subscription IDs
NONPROD_ID=$(az account list --query "[?contains(name, 'Non-Prod') || contains(name, 'nonprod') || contains(name, 'NonProd')].id" -o tsv | head -n 1)
PROD_ID=$(az account list --query "[?contains(name, 'Prod') && !contains(name, 'Non')].id" -o tsv | head -n 1)

if [ -z "$NONPROD_ID" ]; then
    echo "⚠️  Non-Production subscription not found"
    echo "   Please create it in Azure Portal first"
    echo "   Or provide the subscription ID manually:"
    read -p "   Non-Prod Subscription ID: " NONPROD_ID
fi

if [ -z "$PROD_ID" ]; then
    echo "⚠️  Production subscription not found"
    echo "   Please create it in Azure Portal first"
    echo "   Or provide the subscription ID manually:"
    read -p "   Prod Subscription ID: " PROD_ID
fi

if [ -z "$NONPROD_ID" ] || [ -z "$PROD_ID" ]; then
    echo "❌ Cannot proceed without both subscription IDs"
    exit 1
fi

echo ""
echo "📋 Found subscriptions:"
echo "   Non-Prod: $NONPROD_ID"
echo "   Prod: $PROD_ID"
echo ""

# Get tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)

# Update terraform.tfvars
cd /Users/venkatamulakaluri/Desktop/Pravenya/infra-global

cat > terraform.tfvars << EOF
tenant_id = "$TENANT_ID"
nonprod_subscription_ids = [
  "/subscriptions/$NONPROD_ID"
]
prod_subscription_ids = [
  "/subscriptions/$PROD_ID"
]
location = "East US"
EOF

echo "✅ Updated terraform.tfvars:"
echo ""
cat terraform.tfvars
echo ""
echo "📝 Next steps:"
echo "   1. Verify the subscription IDs are correct"
echo "   2. Run: terraform init"
echo "   3. Run: terraform plan"
echo "   4. Run: terraform apply"

