#!/bin/bash

# Script to grant required Azure RBAC roles to GitHub Actions service principal
# Run this as a Global Administrator

set -e

# Service Principal details
SERVICE_PRINCIPAL_CLIENT_ID="e2d49ead-387c-4032-a71b-91c19b72ed27"
SERVICE_PRINCIPAL_NAME="pravenya-github-actions"

echo "🔐 Granting Azure RBAC roles to service principal: $SERVICE_PRINCIPAL_NAME"
echo "   Client ID: $SERVICE_PRINCIPAL_CLIENT_ID"
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
    exit 1
fi

echo "✅ Found service principal Object ID: $SP_OBJECT_ID"
echo ""

# Get tenant root management group ID
echo "📋 Getting tenant root management group..."
TENANT_ID=$(az account show --query tenantId -o tsv)
TENANT_ROOT_MG="/providers/Microsoft.Management/managementGroups/${TENANT_ID}"

echo "✅ Tenant root management group: $TENANT_ROOT_MG"
echo ""

# Grant required roles
echo "🔑 Granting Azure RBAC roles..."
echo ""

# 1. Management Group Contributor (at tenant root level)
echo "1. Granting 'Management Group Contributor' role at tenant root..."
if az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "Management Group Contributor" \
    --scope "$TENANT_ROOT_MG" \
    > /dev/null 2>&1; then
    echo "   ✅ Successfully granted Management Group Contributor"
else
    # Check if already assigned
    if az role assignment list --assignee "$SP_OBJECT_ID" --scope "$TENANT_ROOT_MG" --query "[?roleDefinitionName=='Management Group Contributor']" -o tsv | grep -q .; then
        echo "   ℹ️  Management Group Contributor already assigned"
    else
        echo "   ❌ Failed to grant Management Group Contributor"
    fi
fi

# 2. Policy Contributor (at tenant root level)
echo "2. Granting 'Policy Contributor' role at tenant root..."
if az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "Policy Contributor" \
    --scope "$TENANT_ROOT_MG" \
    > /dev/null 2>&1; then
    echo "   ✅ Successfully granted Policy Contributor"
else
    # Check if already assigned
    if az role assignment list --assignee "$SP_OBJECT_ID" --scope "$TENANT_ROOT_MG" --query "[?roleDefinitionName=='Policy Contributor']" -o tsv | grep -q .; then
        echo "   ℹ️  Policy Contributor already assigned"
    else
        echo "   ❌ Failed to grant Policy Contributor"
    fi
fi

# 3. User Access Administrator (at tenant root level)
echo "3. Granting 'User Access Administrator' role at tenant root..."
if az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "User Access Administrator" \
    --scope "$TENANT_ROOT_MG" \
    > /dev/null 2>&1; then
    echo "   ✅ Successfully granted User Access Administrator"
else
    # Check if already assigned
    if az role assignment list --assignee "$SP_OBJECT_ID" --scope "$TENANT_ROOT_MG" --query "[?roleDefinitionName=='User Access Administrator']" -o tsv | grep -q .; then
        echo "   ℹ️  User Access Administrator already assigned"
    else
        echo "   ❌ Failed to grant User Access Administrator"
    fi
fi

echo ""
echo "📋 Verifying role assignments..."
echo ""
az role assignment list \
    --assignee "$SP_OBJECT_ID" \
    --scope "$TENANT_ROOT_MG" \
    --query "[].{Role:roleDefinitionName, Scope:scope}" \
    -o table

echo ""
echo "✅ Done! The service principal now has the required Azure RBAC roles."
echo ""
echo "📝 Granted roles:"
echo "   • Management Group Contributor (at tenant root)"
echo "   • Policy Contributor (at tenant root)"
echo "   • User Access Administrator (at tenant root)"
echo ""
echo "⏳ Note: It may take 2-5 minutes for role assignments to propagate."
echo "   Wait a few minutes before re-running Terraform apply."
echo ""

