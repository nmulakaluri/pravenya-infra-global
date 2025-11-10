#!/bin/bash

# Script to grant Storage Blob Data Contributor role to service principal
# This is required for the service principal to access Terraform state in Azure Storage
#
# Prerequisites:
# - You must be logged in as Owner or User Access Administrator
# - The service principal must already exist
#
# Usage:
#   ./grant-storage-permissions.sh <SERVICE_PRINCIPAL_CLIENT_ID> [STORAGE_ACCOUNT_NAME] [SUBSCRIPTION_ID]

set -e

if [ -z "$1" ]; then
    echo "❌ Error: Service Principal Client ID is required"
    echo ""
    echo "Usage:"
    echo "  ./grant-storage-permissions.sh <SERVICE_PRINCIPAL_CLIENT_ID> [STORAGE_ACCOUNT_NAME] [SUBSCRIPTION_ID]"
    echo ""
    echo "Example:"
    echo "  ./grant-storage-permissions.sh xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    echo "  ./grant-storage-permissions.sh xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx tfstatepravenya74f45b b99aacbc-2d02-49b1-9d5d-561ba9909ff5"
    exit 1
fi

SERVICE_PRINCIPAL_CLIENT_ID=$1
STORAGE_ACCOUNT_NAME=${2:-"tfstatepravenya74f45b"}
RESOURCE_GROUP="rg-pravenya-terraform-state"

echo "🔐 Granting Storage Blob Data Contributor role to service principal: $SERVICE_PRINCIPAL_CLIENT_ID"
echo ""

# Check if logged in
if ! az account show > /dev/null 2>&1; then
    echo "❌ Error: Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Get subscription ID if not provided
if [ -z "$3" ]; then
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
else
    SUBSCRIPTION_ID=$3
fi

echo "📋 Configuration:"
echo "   Service Principal Client ID: $SERVICE_PRINCIPAL_CLIENT_ID"
echo "   Storage Account: $STORAGE_ACCOUNT_NAME"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo ""

# Get the service principal object ID
echo "📋 Getting service principal details..."
SP_OBJECT_ID=$(az ad sp show --id "$SERVICE_PRINCIPAL_CLIENT_ID" --query id -o tsv 2>/dev/null || echo "")

if [ -z "$SP_OBJECT_ID" ]; then
    echo "❌ Error: Service principal not found with Client ID: $SERVICE_PRINCIPAL_CLIENT_ID"
    echo "   Please verify the Client ID is correct."
    exit 1
fi

echo "✅ Found service principal: $SP_OBJECT_ID"
echo ""

# Check if storage account exists
echo "📋 Verifying storage account exists..."
if ! az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" > /dev/null 2>&1; then
    echo "❌ Error: Storage account '$STORAGE_ACCOUNT_NAME' not found in resource group '$RESOURCE_GROUP'"
    echo "   Please verify the storage account name and resource group."
    exit 1
fi

echo "✅ Storage account found"
echo ""

# Grant Storage Blob Data Contributor role
echo "🔑 Granting 'Storage Blob Data Contributor' role..."
STORAGE_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"

az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "Storage Blob Data Contributor" \
    --scope "$STORAGE_SCOPE" \
    > /dev/null 2>&1 || {
    echo "⚠️  Warning: Role may already be assigned or insufficient permissions"
    echo "   Checking if role is already assigned..."
    
    # Check if role is already assigned
    if az role assignment list --assignee "$SP_OBJECT_ID" --scope "$STORAGE_SCOPE" --query "[?roleDefinitionName=='Storage Blob Data Contributor']" -o tsv | grep -q .; then
        echo "✅ Role is already assigned"
    else
        echo "❌ Failed to assign role. You may need Owner or User Access Administrator permissions."
        exit 1
    fi
}

echo ""
echo "✅ Done! The service principal now has Storage Blob Data Contributor role on the storage account."
echo ""
echo "📝 Granted permissions:"
echo "   • Storage Blob Data Contributor (on storage account: $STORAGE_ACCOUNT_NAME)"
echo ""
echo "⏳ Note: It may take a few minutes for role assignments to propagate."
echo "   Wait 2-5 minutes before re-running Terraform init."
echo ""

