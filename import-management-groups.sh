#!/bin/bash

# Script to import existing management groups into Terraform state
# This is needed when management groups were created outside of Terraform

set -e

echo "📦 Importing existing management groups into Terraform state..."
echo ""

cd "$(dirname "$0")"

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Error: Terraform not initialized. Please run 'terraform init' first."
    exit 1
fi

# Management groups to import
declare -A MGS=(
    ["root"]="mg-pravenya-root"
    ["nonprod"]="mg-pravenya-nonprod"
    ["prod"]="mg-pravenya-prod"
)

echo "🔍 Checking which management groups need to be imported..."
echo ""

# Import each management group
for resource_name in "${!MGS[@]}"; do
    mg_name="${MGS[$resource_name]}"
    mg_id="/providers/Microsoft.Management/managementGroups/${mg_name}"
    
    echo "Importing ${mg_name}..."
    
    # Check if already in state
    if terraform state show "azurerm_management_group.${resource_name}" > /dev/null 2>&1; then
        echo "   ℹ️  ${mg_name} already in state, skipping..."
    else
        # Import the management group
        if terraform import "azurerm_management_group.${resource_name}" "${mg_id}" 2>&1; then
            echo "   ✅ Successfully imported ${mg_name}"
        else
            echo "   ⚠️  Failed to import ${mg_name} (may already exist or need different approach)"
        fi
    fi
    echo ""
done

echo "✅ Import process complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Run 'terraform plan' to see if there are any differences"
echo "   2. If there are differences, review and apply them"
echo "   3. Run 'terraform apply' to ensure everything is in sync"
echo ""

