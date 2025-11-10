#!/bin/bash

# Script to grant Azure RBAC roles to a service principal
# This is required for the service principal to manage:
# - Management Groups
# - Policy Assignments
# - Role Assignments
#
# Prerequisites:
# - You must be logged in as a Global Administrator or Owner
# - The service principal must already exist
#
# Usage:
#   ./grant-azure-rbac-roles.sh <SERVICE_PRINCIPAL_CLIENT_ID> [SUBSCRIPTION_ID]

set -e

if [ -z "$1" ]; then
    echo "❌ Error: Service Principal Client ID is required"
    echo ""
    echo "Usage:"
    echo "  ./grant-azure-rbac-roles.sh <SERVICE_PRINCIPAL_CLIENT_ID> [SUBSCRIPTION_ID]"
    echo ""
    echo "Example:"
    echo "  ./grant-azure-rbac-roles.sh xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    echo "  ./grant-azure-rbac-roles.sh xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /subscriptions/xxxx-xxxx-xxxx-xxxx"
    exit 1
fi

SERVICE_PRINCIPAL_CLIENT_ID=$1
SUBSCRIPTION_ID=${2:-""}

echo "🔐 Granting Azure RBAC roles to service principal: $SERVICE_PRINCIPAL_CLIENT_ID"
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

# Get tenant root management group ID
echo "📋 Getting tenant root management group..."
TENANT_ROOT_MG=$(az account management-group list --query "[?name=='Tenant Root Group'].name" -o tsv 2>/dev/null || echo "")

if [ -z "$TENANT_ROOT_MG" ]; then
    # Try alternative method
    TENANT_ROOT_MG=$(az account show --query tenantId -o tsv)
    TENANT_ROOT_MG="/providers/Microsoft.Management/managementGroups/${TENANT_ROOT_MG}"
else
    TENANT_ROOT_MG="/providers/Microsoft.Management/managementGroups/${TENANT_ROOT_MG}"
fi

echo "✅ Tenant root management group: $TENANT_ROOT_MG"
echo ""

# Required roles
echo "🔑 Granting Azure RBAC roles..."
echo ""

# 1. Management Group Contributor (at tenant root level)
echo "1. Granting 'Management Group Contributor' role at tenant root..."
az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "Management Group Contributor" \
    --scope "$TENANT_ROOT_MG" \
    > /dev/null 2>&1 || echo "   ⚠️  Warning: Role may already be assigned or insufficient permissions"

# 2. Policy Contributor (at tenant root level)
echo "2. Granting 'Policy Contributor' role at tenant root..."
az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "Policy Contributor" \
    --scope "$TENANT_ROOT_MG" \
    > /dev/null 2>&1 || echo "   ⚠️  Warning: Role may already be assigned or insufficient permissions"

# 3. User Access Administrator (at tenant root level) - for role assignments
echo "3. Granting 'User Access Administrator' role at tenant root..."
az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "User Access Administrator" \
    --scope "$TENANT_ROOT_MG" \
    > /dev/null 2>&1 || echo "   ⚠️  Warning: Role may already be assigned or insufficient permissions"

# If subscription ID is provided, also grant roles at subscription level
if [ -n "$SUBSCRIPTION_ID" ]; then
    echo ""
    echo "📋 Granting additional roles at subscription level..."
    echo ""
    
    # Extract subscription ID if full path provided
    if [[ "$SUBSCRIPTION_ID" == *"/subscriptions/"* ]]; then
        SUB_ID=$(echo "$SUBSCRIPTION_ID" | sed 's|.*/subscriptions/||')
    else
        SUB_ID="$SUBSCRIPTION_ID"
    fi
    
    SUB_SCOPE="/subscriptions/$SUB_ID"
    
    echo "4. Granting 'Policy Contributor' role at subscription level..."
    az role assignment create \
        --assignee "$SP_OBJECT_ID" \
        --role "Policy Contributor" \
        --scope "$SUB_SCOPE" \
        > /dev/null 2>&1 || echo "   ⚠️  Warning: Role may already be assigned"
    
    echo "5. Granting 'User Access Administrator' role at subscription level..."
    az role assignment create \
        --assignee "$SP_OBJECT_ID" \
        --role "User Access Administrator" \
        --scope "$SUB_SCOPE" \
        > /dev/null 2>&1 || echo "   ⚠️  Warning: Role may already be assigned"
fi

echo ""
echo "✅ Done! The service principal now has the required Azure RBAC roles."
echo ""
echo "📝 Granted roles:"
echo "   • Management Group Contributor (at tenant root)"
echo "   • Policy Contributor (at tenant root)"
echo "   • User Access Administrator (at tenant root)"
if [ -n "$SUBSCRIPTION_ID" ]; then
    echo "   • Policy Contributor (at subscription level)"
    echo "   • User Access Administrator (at subscription level)"
fi
echo ""
echo "⏳ Note: It may take a few minutes for role assignments to propagate."
echo "   Wait 2-5 minutes before re-running Terraform."
echo ""

