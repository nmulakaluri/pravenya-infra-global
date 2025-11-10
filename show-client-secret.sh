#!/bin/bash

# Script to display the client secret value for updating GitHub Secrets
# This helps ensure you're copying the correct secret value

set -e

echo "🔐 GitHub Actions Service Principal Client Secret"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd /Users/venkatamulakaluri/Desktop/Pravenya/pravenya-infra-global

# Get Client Secret
CLIENT_SECRET=$(terraform output -raw github_actions_client_secret 2>/dev/null || echo "")

if [ -z "$CLIENT_SECRET" ]; then
    echo "❌ Error: Client Secret not found in Terraform state."
    echo ""
    echo "This could mean:"
    echo "  1. Terraform hasn't been applied yet"
    echo "  2. The secret was deleted from Azure AD"
    echo "  3. The Terraform state is not available"
    echo ""
    echo "If the secret was deleted, you'll need to create a new one."
    exit 1
fi

echo "Secret Name: AZURE_CLIENT_SECRET"
echo ""
echo "Secret Value (copy this entire value):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$CLIENT_SECRET"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 To update GitHub Secret:"
echo ""
echo "1. Go to: https://github.com/nmulakaluri/pravenya-infra-global/settings/secrets/actions"
echo "2. Find 'AZURE_CLIENT_SECRET'"
echo "3. Click 'Update'"
echo "4. Paste the secret value above (the entire value starting with 'v1B8Q~')"
echo "5. Click 'Update secret'"
echo ""
echo "⚠️  IMPORTANT:"
echo "   • Copy the ENTIRE value (including 'v1B8Q~' at the start)"
echo "   • Make sure you're copying the VALUE, not the Secret ID"
echo "   • The value should start with 'v1B8Q~'"
echo ""

