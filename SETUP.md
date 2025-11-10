# Setup Guide for infra-global

This guide will help you set up the `infra-global` repository step by step.

## Prerequisites Checklist

- [ ] Azure account with appropriate permissions
- [ ] Azure CLI installed and authenticated
- [ ] Terraform installed (>= 1.0)
- [ ] GitHub organization account
- [ ] Git installed

## Step 1: Azure Authentication

First, authenticate with Azure:

```bash
az login
az account list --output table
```

Note your:
- **Tenant ID**: `az account show --query tenantId -o tsv`
- **Subscription ID**: `az account show --query id -o tsv`

## Step 2: Create Backend Storage Account

The Terraform backend needs a storage account to store state files.

```bash
# Set variables (adjust location as needed)
RESOURCE_GROUP="rg-pravenya-terraform-state"
STORAGE_ACCOUNT="tfstatepravenya"
LOCATION="eastus"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --subscription $SUBSCRIPTION_ID

# Create storage account (name must be globally unique)
STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT}$(openssl rand -hex 3)"
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --subscription $SUBSCRIPTION_ID

# Create container
az storage container create \
  --name state \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login

# Get storage account key (needed for backend configuration)
STORAGE_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query "[0].value" -o tsv)

echo "Storage Account Name: $STORAGE_ACCOUNT_NAME"
echo "Storage Key: $STORAGE_KEY"
```

**Important**: Update `backend.tf` with the actual storage account name if it's different from `tfstatepravenya`.

## Step 3: Configure Terraform Variables

Create a `terraform.tfvars` file (this will NOT be committed to git):

```bash
cd /Users/venkatamulakaluri/Desktop/Pravenya/infra-global
```

Create `terraform.tfvars`:

```hcl
tenant_id = "<your-tenant-id>"
nonprod_subscription_ids = [
  # Add your nonprod subscription IDs here
  # Example: "/subscriptions/12345678-1234-1234-1234-123456789012"
]
prod_subscription_ids = [
  # Add your prod subscription IDs here
  # Example: "/subscriptions/87654321-4321-4321-4321-210987654321"
]
location = "East US"
```

Get your tenant ID:
```bash
az account show --query tenantId -o tsv
```

## Step 4: Initialize Terraform

```bash
cd /Users/venkatamulakaluri/Desktop/Pravenya/infra-global
terraform init
```

If you need to configure the backend with a storage key:

```bash
terraform init \
  -backend-config="storage_account_name=tfstatepravenya" \
  -backend-config="container_name=state" \
  -backend-config="key=global.terraform.tfstate" \
  -backend-config="resource_group_name=rg-pravenya-terraform-state"
```

## Step 5: Plan and Review

```bash
terraform plan
```

Review the planned changes carefully. You should see:
- 3 management groups (mg-pravenya-root, mg-pravenya-nonprod, mg-pravenya-prod)
- Entra ID groups (pravenya-admins, pravenya-devs, pravenya-viewers)
- App registration (pravenya-web)
- Policy definition and assignment

## Step 6: Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted, or use:
```bash
terraform apply -auto-approve
```

## Step 7: Set Up GitHub Repository

### Option A: Using GitHub CLI (gh)

```bash
cd /Users/venkatamulakaluri/Desktop/Pravenya/infra-global

# Initialize git if not already done
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: infra-global Terraform configuration"

# Create repository in your GitHub org (replace ORG_NAME)
gh repo create ORG_NAME/infra-global --public --source=. --remote=origin

# Push to GitHub
git push -u origin main
```

### Option B: Using GitHub Web Interface

1. Go to your GitHub organization
2. Click "New repository"
3. Name it: `infra-global`
4. Choose visibility (private recommended)
5. **Don't** initialize with README (we already have one)
6. Click "Create repository"
7. Then run:

```bash
cd /Users/venkatamulakaluri/Desktop/Pravenya/infra-global
git init
git add .
git commit -m "Initial commit: infra-global Terraform configuration"
git branch -M main
git remote add origin https://github.com/YOUR_ORG/infra-global.git
git push -u origin main
```

## Step 8: Verify Outputs

After applying, check the outputs:

```bash
terraform output
```

You should see:
- `entra_group_ids`: Object IDs of the Entra ID groups
- `service_principal_id`: Service principal object ID
- `app_registration_client_id`: App registration client ID
- `management_group_ids`: Management group IDs

Save these outputs - you'll need them for other repositories!

## Troubleshooting

### Backend Configuration Issues

If you get backend errors:
```bash
# Verify storage account exists
az storage account show --name tfstatepravenya --resource-group rg-pravenya-terraform-state

# Verify container exists
az storage container show --name state --account-name tfstatepravenya --auth-mode login
```

### Permission Issues

You need these permissions:
- **Management Group Contributor** (to create management groups)
- **Global Administrator** or **User Administrator** (for Entra ID)
- **Owner** or **Contributor** on subscriptions

Check your permissions:
```bash
az role assignment list --assignee $(az account show --query user.name -o tsv) --all
```

### Subscription Association Issues

If you don't have subscriptions yet, you can leave the subscription ID lists empty:
```hcl
nonprod_subscription_ids = []
prod_subscription_ids = []
```

You can add subscriptions later by updating the tfvars file and running `terraform apply` again.

## Next Steps

Once `infra-global` is set up:
1. Note the outputs (especially Entra ID group object IDs)
2. Set up `infra-nonprod` or `infra-prod` next
3. Use the outputs from this repo in those repos

