#!/bin/bash

# Script to get GitHub Secrets values from Terraform outputs
# Run this after applying terraform to get the values for GitHub Secrets

set -e

echo "🔍 Getting GitHub Secrets values from Terraform outputs..."
echo ""

cd /Users/venkatamulakaluri/Desktop/Pravenya/pravenya-infra-global

# Check if terraform has been applied
if [ ! -f .terraform/terraform.tfstate ] && [ ! -f terraform.tfstate ]; then
    echo "❌ Error: Terraform state not found. Please run 'terraform apply' first."
    exit 1
fi

# Get outputs
echo "📋 GitHub Secrets Values:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get Client ID
CLIENT_ID=$(terraform output -raw github_actions_client_id 2>/dev/null || echo "")
if [ -z "$CLIENT_ID" ]; then
    echo "⚠️  Client ID not found. Make sure terraform has been applied."
else
    echo "1. Secret Name: AZURE_CLIENT_ID"
    echo "   Value: $CLIENT_ID"
    echo ""
fi

# Get Client Secret
CLIENT_SECRET=$(terraform output -raw github_actions_client_secret 2>/dev/null || echo "")
if [ -z "$CLIENT_SECRET" ]; then
    echo "⚠️  Client Secret not found. Make sure terraform has been applied."
else
    echo "2. Secret Name: AZURE_CLIENT_SECRET"
    echo "   Value: $CLIENT_SECRET"
    echo "   ⚠️  IMPORTANT: Save this value - it's only shown once!"
    echo ""
fi

# Get Subscription ID from terraform.tfvars or use default
if [ -f terraform.tfvars ]; then
    SUBSCRIPTION_ID=$(grep -E "^subscription_id" terraform.tfvars | cut -d'"' -f2 | head -n 1)
fi
if [ -z "$SUBSCRIPTION_ID" ]; then
    SUBSCRIPTION_ID="b99aacbc-2d02-49b1-9d5d-561ba9909ff5"
fi
echo "3. Secret Name: AZURE_SUBSCRIPTION_ID"
echo "   Value: $SUBSCRIPTION_ID"
echo ""

# Get Tenant ID from terraform.tfvars or use default
if [ -f terraform.tfvars ]; then
    TENANT_ID=$(grep -E "^tenant_id" terraform.tfvars | cut -d'"' -f2 | head -n 1)
fi
if [ -z "$TENANT_ID" ]; then
    TENANT_ID="2581608f-9d7e-4da3-a33d-499c7f164ac4"
fi
echo "4. Secret Name: AZURE_TENANT_ID"
echo "   Value: $TENANT_ID"
echo ""

# Get full credentials JSON
echo "5. Secret Name: AZURE_CREDENTIALS"
echo "   Value: (Full JSON below)"
echo ""
CREDENTIALS_JSON=$(cat <<EOF
{
  "clientId": "$CLIENT_ID",
  "clientSecret": "$CLIENT_SECRET",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "tenantId": "$TENANT_ID",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
EOF
)
echo "$CREDENTIALS_JSON"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Copy these values and add them as secrets in GitHub:"
echo "   Repository → Settings → Secrets and variables → Actions → New repository secret"
echo ""
echo "📝 Quick copy commands:"
echo ""
echo "   # Client ID"
echo "   echo '$CLIENT_ID' | pbcopy"
echo ""
echo "   # Client Secret"
echo "   echo '$CLIENT_SECRET' | pbcopy"
echo ""
echo "   # Subscription ID"
echo "   echo '$SUBSCRIPTION_ID' | pbcopy"
echo ""
echo "   # Tenant ID"
echo "   echo '$TENANT_ID' | pbcopy"
echo ""

