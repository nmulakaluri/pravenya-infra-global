# Quick Fix: Grant Required Azure RBAC Roles

## Problem
The service principal used in GitHub Actions doesn't have sufficient permissions to:
- Create/delete Management Groups
- Create/delete Policy Assignments  
- Create/delete Role Assignments

## Solution

### Step 1: Get Your Service Principal Client ID

The Client ID is stored in your GitHub repository secrets as `AZURE_CLIENT_ID`.

You can find it by:
1. Going to your GitHub repository → Settings → Secrets and variables → Actions
2. Looking for `AZURE_CLIENT_ID` secret
3. Or running: `terraform output -json github_actions_service_principal` (if you have access)

### Step 2: Grant Required Roles

**Option A: Using the Script (Recommended)**

```bash
cd /Users/venkatamulakaluri/Desktop/Pravenya/pravenya-infra-global

# Make sure you're logged in as Global Administrator or Owner
az login

# Run the script with your service principal Client ID
./grant-azure-rbac-roles.sh <YOUR_SERVICE_PRINCIPAL_CLIENT_ID>
```

**Option B: Manual Azure CLI Commands**

```bash
# Get your service principal Client ID from GitHub Secrets
SERVICE_PRINCIPAL_CLIENT_ID="<YOUR_CLIENT_ID>"

# Get the service principal Object ID
SP_OBJECT_ID=$(az ad sp show --id "$SERVICE_PRINCIPAL_CLIENT_ID" --query id -o tsv)

# Get tenant root management group
TENANT_ID=$(az account show --query tenantId -o tsv)
TENANT_ROOT_MG="/providers/Microsoft.Management/managementGroups/${TENANT_ID}"

# Grant Management Group Contributor
az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "Management Group Contributor" \
    --scope "$TENANT_ROOT_MG"

# Grant Policy Contributor
az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "Policy Contributor" \
    --scope "$TENANT_ROOT_MG"

# Grant User Access Administrator
az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "User Access Administrator" \
    --scope "$TENANT_ROOT_MG"
```

### Step 3: Wait for Role Propagation

**Important:** Azure role assignments can take 2-5 minutes to propagate. Wait a few minutes before re-running Terraform.

### Step 4: Re-run Terraform Apply

After waiting a few minutes, re-run your GitHub Actions workflow or Terraform apply.

## Required Roles Summary

The service principal needs these roles at the **tenant root management group** level:

1. **Management Group Contributor** - To create/delete management groups
2. **Policy Contributor** - To create/delete policy assignments
3. **User Access Administrator** - To create/delete role assignments

## Prerequisites

- You must be logged in as a **Global Administrator** or have **Owner** role at tenant root
- The service principal must already exist
- Azure CLI must be installed and authenticated

## Verification

After granting roles, you can verify them:

```bash
# Get service principal Object ID
SP_OBJECT_ID=$(az ad sp show --id "<YOUR_CLIENT_ID>" --query id -o tsv)

# List role assignments at tenant root
TENANT_ID=$(az account show --query tenantId -o tsv)
TENANT_ROOT_MG="/providers/Microsoft.Management/managementGroups/${TENANT_ID}"

az role assignment list \
    --assignee "$SP_OBJECT_ID" \
    --scope "$TENANT_ROOT_MG" \
    --query "[].{Role:roleDefinitionName, Scope:scope}" \
    -o table
```

You should see:
- Management Group Contributor
- Policy Contributor
- User Access Administrator

