# Quick Start Guide - infra-global

Get up and running with `infra-global` in 5 steps!

## 🚀 Quick Start

### Step 1: Install Prerequisites

```bash
cd /Users/venkatamulakaluri/Desktop/Pravenya/infra-global
./install-prerequisites.sh
```

Or install manually:
- **Azure CLI**: `brew install azure-cli`
- **Terraform**: `brew install terraform`
- **GitHub CLI** (optional): `brew install gh`

### Step 2: Authenticate

```bash
# Azure
az login

# GitHub (optional, but recommended)
gh auth login
```

### Step 3: Create Backend Storage

```bash
./setup-backend.sh
```

This creates the Azure Storage account for Terraform state. **Save the storage account name** that's displayed!

### Step 4: Configure Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars  # or use your preferred editor
```

Get your Tenant ID:
```bash
az account show --query tenantId -o tsv
```

### Step 5: Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted, or use `terraform apply -auto-approve`

## 📋 What Gets Created

After applying, you'll have:
- ✅ 3 Management Groups (mg-pravenya-root, mg-pravenya-nonprod, mg-pravenya-prod)
- ✅ 3 Entra ID Groups (pravenya-admins, pravenya-devs, pravenya-viewers)
- ✅ App Registration (pravenya-web) with Service Principal
- ✅ Custom Policy (Require tags) assigned to mg-pravenya-root

## 🔗 Set Up GitHub Repository

### Option A: Using GitHub CLI

```bash
git init
git add .
git commit -m "Initial commit: infra-global Terraform configuration"
gh repo create YOUR_ORG/infra-global --public --source=. --remote=origin
git push -u origin main
```

### Option B: Using GitHub Web

1. Go to your GitHub org → New repository
2. Name: `infra-global`
3. Don't initialize with README
4. Then run:

```bash
git init
git add .
git commit -m "Initial commit: infra-global Terraform configuration"
git branch -M main
git remote add origin https://github.com/YOUR_ORG/infra-global.git
git push -u origin main
```

## 📝 Save Outputs

After applying, get the outputs you'll need for other repos:

```bash
terraform output
```

**Important outputs:**
- `entra_group_ids` - Object IDs of Entra ID groups
- `service_principal_id` - Service principal object ID
- `app_registration_client_id` - App registration client ID

## 🆘 Need Help?

- See `SETUP.md` for detailed instructions
- See `README.md` for full documentation
- Run `./check-prerequisites.sh` to verify your setup

## ✅ Next Steps

Once `infra-global` is set up:
1. Note the outputs (especially Entra ID group object IDs)
2. Set up `infra-nonprod` or `infra-prod` next
3. Use the outputs from this repo in those repos

