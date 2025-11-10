#!/bin/bash

# Setup script for creating Terraform backend storage account
# This script creates the Azure Storage account needed for Terraform state

set -e

echo "🚀 Setting up Terraform backend storage account..."

# Configuration
RESOURCE_GROUP="rg-pravenya-terraform-state"
STORAGE_ACCOUNT_PREFIX="tfstatepravenya"
LOCATION="eastus"

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "📋 Current Azure Configuration:"
echo "   Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo "   Tenant ID: $TENANT_ID"
echo ""

# Check if resource group exists
if az group show --name $RESOURCE_GROUP --subscription $SUBSCRIPTION_ID &>/dev/null; then
    echo "✅ Resource group '$RESOURCE_GROUP' already exists"
else
    echo "📦 Creating resource group '$RESOURCE_GROUP'..."
    az group create \
        --name $RESOURCE_GROUP \
        --location $LOCATION \
        --subscription $SUBSCRIPTION_ID
    echo "✅ Resource group created"
fi

# Generate unique storage account name
STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_PREFIX}$(openssl rand -hex 3 | tr '[:upper:]' '[:lower:]')"

# Check if storage account name is available
echo "🔍 Checking storage account name availability..."
if az storage account check-name --name $STORAGE_ACCOUNT_NAME --query nameAvailable -o tsv | grep -q true; then
    echo "✅ Storage account name '$STORAGE_ACCOUNT_NAME' is available"
else
    echo "⚠️  Storage account name '$STORAGE_ACCOUNT_NAME' is not available, generating new name..."
    STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_PREFIX}$(openssl rand -hex 4 | tr '[:upper:]' '[:lower:]')"
fi

# Check if storage account already exists
if az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --subscription $SUBSCRIPTION_ID &>/dev/null; then
    echo "✅ Storage account '$STORAGE_ACCOUNT_NAME' already exists"
else
    echo "📦 Creating storage account '$STORAGE_ACCOUNT_NAME'..."
    az storage account create \
        --name $STORAGE_ACCOUNT_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --sku Standard_LRS \
        --subscription $SUBSCRIPTION_ID \
        --allow-blob-public-access false \
        --min-tls-version TLS1_2
    echo "✅ Storage account created"
fi

# Create container
echo "📦 Creating storage container 'state'..."
az storage container create \
    --name state \
    --account-name $STORAGE_ACCOUNT_NAME \
    --auth-mode login \
    --public-access off \
    || echo "⚠️  Container may already exist"

echo "✅ Container created"

# Get storage account key
echo "🔑 Retrieving storage account key..."
STORAGE_KEY=$(az storage account keys list \
    --resource-group $RESOURCE_GROUP \
    --account-name $STORAGE_ACCOUNT_NAME \
    --query "[0].value" -o tsv)

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "📝 Update your backend.tf with the following storage account name:"
echo "   Storage Account Name: $STORAGE_ACCOUNT_NAME"
echo ""
echo "⚠️  IMPORTANT: Save the storage account name and key securely!"
echo "   Storage Account: $STORAGE_ACCOUNT_NAME"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Container: state"
echo ""
echo "💡 If you need to configure backend with key, use:"
echo "   terraform init -backend-config=\"storage_account_name=$STORAGE_ACCOUNT_NAME\" \\"
echo "                  -backend-config=\"access_key=$STORAGE_KEY\" \\"
echo "                  -backend-config=\"container_name=state\" \\"
echo "                  -backend-config=\"key=global.terraform.tfstate\" \\"
echo "                  -backend-config=\"resource_group_name=$RESOURCE_GROUP\""

