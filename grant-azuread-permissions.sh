#!/bin/bash

# Script to grant Azure AD (Entra ID) permissions to a service principal
# This is required for the service principal to manage Azure AD resources via Terraform
#
# Prerequisites:
# - You must be logged in as a Global Administrator or User Administrator
# - The service principal must already exist
#
# Usage:
#   ./grant-azuread-permissions.sh <SERVICE_PRINCIPAL_CLIENT_ID>

set -e

if [ -z "$1" ]; then
    echo "❌ Error: Service Principal Client ID is required"
    echo ""
    echo "Usage:"
    echo "  ./grant-azuread-permissions.sh <SERVICE_PRINCIPAL_CLIENT_ID>"
    echo ""
    echo "Example:"
    echo "  ./grant-azuread-permissions.sh xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    exit 1
fi

SERVICE_PRINCIPAL_CLIENT_ID=$1

echo "🔐 Granting Azure AD permissions to service principal: $SERVICE_PRINCIPAL_CLIENT_ID"
echo ""

# Check if logged in
if ! az account show > /dev/null 2>&1; then
    echo "❌ Error: Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

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

# Microsoft Graph API App ID
GRAPH_API_APP_ID="00000003-0000-0000-c000-000000000000"

# Required Microsoft Graph API permissions (Application permissions)
# These are the permissions needed to manage Azure AD resources via Terraform
PERMISSIONS=(
    "Group.ReadWrite.All"           # Read and write all groups
    "Application.ReadWrite.All"    # Read and write all applications
    "Directory.ReadWrite.All"       # Read and write directory data
    "User.ReadWrite.All"            # Read and write all users (if needed)
)

echo "🔑 Granting Microsoft Graph API permissions..."
echo ""

for PERMISSION in "${PERMISSIONS[@]}"; do
    echo "  - Granting: $PERMISSION"
    
    # Get the permission ID
    PERMISSION_ID=$(az ad sp show --id "$GRAPH_API_APP_ID" --query "appRoles[?value=='$PERMISSION'].id" -o tsv)
    
    if [ -z "$PERMISSION_ID" ]; then
        echo "    ⚠️  Warning: Permission '$PERMISSION' not found. Skipping..."
        continue
    fi
    
    # Grant the permission
    az ad app permission add \
        --id "$SERVICE_PRINCIPAL_CLIENT_ID" \
        --api "$GRAPH_API_APP_ID" \
        --api-permissions "$PERMISSION_ID=Role" \
        > /dev/null 2>&1 || echo "    ⚠️  Warning: Permission may already be granted"
done

echo ""
echo "✅ Permissions granted. Now granting admin consent..."
echo ""

# Grant admin consent for all permissions
az ad app permission admin-consent --id "$SERVICE_PRINCIPAL_CLIENT_ID" > /dev/null 2>&1 || {
    echo "⚠️  Warning: Could not grant admin consent automatically."
    echo "   You may need to grant admin consent manually:"
    echo "   1. Go to Azure Portal → Azure Active Directory → App registrations"
    echo "   2. Find your app (Client ID: $SERVICE_PRINCIPAL_CLIENT_ID)"
    echo "   3. Go to API permissions"
    echo "   4. Click 'Grant admin consent for [Your Organization]'"
}

echo ""
echo "✅ Done! The service principal now has Azure AD permissions."
echo ""
echo "📝 Next steps:"
echo "   1. Wait a few minutes for permissions to propagate"
echo "   2. Re-run your Terraform plan/apply"
echo "   3. If you still get permission errors, verify admin consent was granted"
echo ""

