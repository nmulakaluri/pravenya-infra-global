# Creating Non-Prod and Prod Subscriptions

## Method 1: Azure Portal (Recommended)

### Step 1: Create Non-Production Subscription

1. Go to [Azure Portal](https://portal.azure.com)
2. Search for "Subscriptions" in the top search bar
3. Click **"+ Add"** or **"Create subscription"**
4. Fill in the details:
   - **Billing Account**: Select your billing account (Praveena Mulakaluri)
   - **Display Name**: `Pravenya Non-Production`
   - **Subscription Name**: `pravenya-nonprod` (this will be the alias)
   - **Billing Profile**: Select your billing profile
   - **Offer Type**: Usually "Microsoft Azure Plan"
5. Click **"Create"**
6. Wait for the subscription to be created (usually takes 1-2 minutes)
7. **Copy the Subscription ID** - you'll need this for Terraform

### Step 2: Create Production Subscription

1. Repeat the same process:
   - **Display Name**: `Pravenya Production`
   - **Subscription Name**: `pravenya-prod`
2. **Copy the Subscription ID**

### Step 3: Get Subscription IDs

After creating both subscriptions, run:

```bash
az account list --output table
```

You should see:
- Azure subscription 1 (current)
- Pravenya Non-Production
- Pravenya Production

### Step 4: Update Terraform Configuration

Once you have the subscription IDs, update `terraform.tfvars`:

```bash
cd /Users/venkatamulakaluri/Desktop/Pravenya/infra-global
```

Edit `terraform.tfvars` and add the subscription IDs:

```hcl
tenant_id = "2581608f-9d7e-4da3-a33d-499c7f164ac4"
nonprod_subscription_ids = [
  "/subscriptions/<NONPROD-SUBSCRIPTION-ID>"
]
prod_subscription_ids = [
  "/subscriptions/<PROD-SUBSCRIPTION-ID>"
]
location = "East US"
```

## Method 2: Using Azure CLI (If you have enrollment account access)

If you have enrollment account permissions, you can try:

```bash
# This requires specific permissions and may not work for all account types
az account alias create --name pravenya-nonprod --billing-scope "/billingAccounts/..."
```

## Quick Script to Update terraform.tfvars

After creating subscriptions, run this to automatically update your terraform.tfvars:

```bash
cd /Users/venkatamulakaluri/Desktop/Pravenya/infra-global

# Get subscription IDs
NONPROD_ID=$(az account list --query "[?name=='Pravenya Non-Production'].id" -o tsv)
PROD_ID=$(az account list --query "[?name=='Pravenya Production'].id" -o tsv)

# Update terraform.tfvars
cat > terraform.tfvars << EOF
tenant_id = "2581608f-9d7e-4da3-a33d-499c7f164ac4"
nonprod_subscription_ids = [
  "/subscriptions/$NONPROD_ID"
]
prod_subscription_ids = [
  "/subscriptions/$PROD_ID"
]
location = "East US"
EOF

echo "✅ Updated terraform.tfvars with subscription IDs"
cat terraform.tfvars
```

## Notes

- **Subscription names** must be unique within your Azure account
- **Subscription IDs** are in the format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- It may take a few minutes for new subscriptions to fully activate
- You may need to register resource providers in each new subscription

