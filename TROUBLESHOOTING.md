# Troubleshooting Guide

## Common Issues and Solutions

### Error: "403 Forbidden - Insufficient privileges to complete the operation" when managing Azure AD resources

**Problem:**
The service principal being used in GitHub Actions doesn't have Azure AD (Entra ID) permissions to manage groups, applications, and service principals.

**Error Message:**
```
Error: Retrieving Group (Group: "...")
unexpected status 403 (403 Forbidden) with error:
Authorization_RequestDenied: Insufficient privileges to complete the operation.
```

**Root Cause:**
When you create a service principal with `az ad sp create-for-rbac`, it only gets Azure Resource Manager permissions (like Contributor), but NOT Microsoft Graph API permissions needed for Azure AD management.

**Solution:**

You need to grant the service principal Microsoft Graph API permissions. There are two approaches:

#### Option 1: Grant Microsoft Graph API Permissions (Recommended)

Use the provided script to grant the necessary permissions:

```bash
# Get your service principal Client ID from GitHub Secrets
# Then run:
./grant-azuread-permissions.sh <YOUR_SERVICE_PRINCIPAL_CLIENT_ID>
```

This script will:
1. Grant the following Microsoft Graph API permissions:
   - `Group.ReadWrite.All` - Read and write all groups
   - `Application.ReadWrite.All` - Read and write all applications
   - `Directory.ReadWrite.All` - Read and write directory data
2. Grant admin consent for these permissions

**Prerequisites:**
- You must be logged in as a Global Administrator or User Administrator
- The service principal must already exist

**Manual Steps (if script doesn't work):**

1. Go to Azure Portal → Azure Active Directory → App registrations
2. Find your service principal (search by Client ID)
3. Go to **API permissions**
4. Click **Add a permission** → **Microsoft Graph** → **Application permissions**
5. Add the following permissions:
   - `Group.ReadWrite.All`
   - `Application.ReadWrite.All`
   - `Directory.ReadWrite.All`
6. Click **Grant admin consent for [Your Organization]**
7. Wait a few minutes for permissions to propagate

#### Option 2: Use a Service Principal with Global Administrator Role

If you have a service principal with Global Administrator role, you can use that instead:

1. Create a service principal with Global Administrator role:
   ```bash
   az ad sp create-for-rbac \
     --name "pravenya-github-actions-admin" \
     --role "Global Administrator" \
     --scopes /subscriptions/<subscription-id>
   ```

2. Update your GitHub Secrets with the new service principal credentials

**Note:** Using Global Administrator role is less secure. Option 1 (specific permissions) is recommended.

### Error: "Cannot apply incomplete plan"

**Problem:**
Terraform plan failed but the workflow tried to apply an incomplete plan file.

**Solution:**
This has been fixed in the workflow. The apply step now:
1. Only runs if the plan step succeeded
2. Validates the plan file before applying
3. Provides clear error messages

### Error: "No value for required variable"

**Problem:**
Terraform requires a variable that isn't set.

**Solution:**
Ensure all required variables are set:
1. In `terraform.tfvars` file (for local runs)
2. Via `TF_VAR_*` environment variables (for GitHub Actions)

For example, `tenant_id` is required and should be set via:
- GitHub Secret: `AZURE_TENANT_ID`
- Environment variable: `TF_VAR_tenant_id` (automatically set from the secret)

### Error: "parsing /subscriptions/: parsing the ResourceGroup ID"

**Problem:**
A resource is trying to use `var.subscription_id` which is empty.

**Solution:**
This has been fixed. Resources that use `subscription_id` are now conditional and only created if `subscription_id` is provided.

If you want to create these resources, set `subscription_id` in your `terraform.tfvars` or via `TF_VAR_subscription_id` environment variable.

### Error: "AuthorizationFailed" - Cannot create/delete Management Groups, Policy Assignments, or Role Assignments

**Problem:**
The service principal doesn't have sufficient Azure RBAC permissions to:
- Create/delete Management Groups
- Create/delete Policy Assignments
- Create/delete Role Assignments

**Error Messages:**
```
Error: unable to create Management Group "mg-pravenya-root": 
Permission to write on resources of type 'Microsoft.Management/managementGroups' is required

Error: deleting Policy Assignment: unexpected status 403 (403 Forbidden) with error: 
AuthorizationFailed: The client does not have authorization to perform action 
'Microsoft.Authorization/policyAssignments/delete'

Error: authorization.RoleAssignmentsClient#Delete: Failure responding to request: 
StatusCode=403 Code="AuthorizationFailed" Message="The client does not have 
authorization to perform action 'Microsoft.Authorization/roleAssignments/delete'"
```

**Root Cause:**
The service principal only has `Contributor` role at subscription level, but needs additional roles at the tenant root management group level to manage:
- Management Groups (requires `Management Group Contributor`)
- Policy Assignments (requires `Policy Contributor`)
- Role Assignments (requires `User Access Administrator`)

**Solution:**

#### Option 1: Grant Roles Using Script (Recommended)

Use the provided script to grant the necessary roles:

```bash
# Get your service principal Client ID from GitHub Secrets
# Then run:
./grant-azure-rbac-roles.sh <YOUR_SERVICE_PRINCIPAL_CLIENT_ID>
```

This script will grant:
- `Management Group Contributor` at tenant root
- `Policy Contributor` at tenant root
- `User Access Administrator` at tenant root

**Prerequisites:**
- You must be logged in as a **Global Administrator** or have **Owner** role at tenant root
- The service principal must already exist

#### Option 2: Grant Roles Manually via Azure Portal

1. Go to Azure Portal → **Management groups**
2. Select the **Tenant Root Group** (or your root management group)
3. Go to **Access control (IAM)**
4. Click **Add** → **Add role assignment**
5. Grant the following roles to your service principal:
   - **Management Group Contributor** - For creating/deleting management groups
   - **Policy Contributor** - For creating/deleting policy assignments
   - **User Access Administrator** - For creating/deleting role assignments
6. Repeat for subscription level if needed

#### Option 3: Grant Roles via Azure CLI

```bash
# Get your service principal Object ID
SP_OBJECT_ID=$(az ad sp show --id <SERVICE_PRINCIPAL_CLIENT_ID> --query id -o tsv)

# Get tenant root management group ID
TENANT_ROOT_MG="/providers/Microsoft.Management/managementGroups/<TENANT_ID>"

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

**Important Notes:**
- You must be a **Global Administrator** or have **Owner** role at tenant root to grant these roles
- Role assignments may take 2-5 minutes to propagate
- If you get "insufficient permissions" errors, you need higher privileges to grant these roles

### Error: "Invalid client secret provided" - Authentication Failed

**Problem:**
The service principal client secret in GitHub Secrets is invalid, expired, or incorrect.

**Error Message:**
```
Error: building account: could not acquire access token to parse claims: 
clientCredentialsToken: received HTTP status 401 with response: 
{"error":"invalid_client","error_description":"AADSTS7000215: Invalid client secret provided. 
Ensure the secret being sent in the request is the client secret value, not the client secret ID..."}
```

**Root Cause:**
The `AZURE_CLIENT_SECRET` in GitHub Secrets is either:
- Expired (application passwords expire after their expiration date)
- Incorrect (wrong value stored)
- Contains the secret ID instead of the secret value
- Was deleted from Azure AD

**Solution:**

#### Option 1: Get Secret from Terraform Output (If Secret Still Exists)

If the secret was created via Terraform and still exists:

```bash
cd pravenya-infra-global
terraform output -raw github_actions_client_secret
```

Then update the GitHub Secret:
1. Go to GitHub → Repository → Settings → Secrets and variables → Actions
2. Find `AZURE_CLIENT_SECRET`
3. Click **Update**
4. Paste the secret value from Terraform output
5. Click **Update secret**

#### Option 2: Create New Application Password via Terraform

If the secret has expired or been deleted, create a new one:

1. **Option A: Update Terraform to create a new password**
   - The `azuread_application_password` resource will create a new password
   - Run `terraform apply` to create a new secret
   - Get the new secret: `terraform output -raw github_actions_client_secret`
   - Update GitHub Secret with the new value

2. **Option B: Create password manually via Azure CLI**
   ```bash
   # Create a new password for the application
   az ad app credential reset \
       --id e2d49ead-387c-4032-a71b-91c19b72ed27 \
       --append \
       --display-name "GitHub Actions Secret"
   ```
   - This will output a new password - save it immediately!
   - Update GitHub Secret `AZURE_CLIENT_SECRET` with the new value

3. **Option C: Create password via Azure Portal**
   - Go to Azure Portal → Azure Active Directory → App registrations
   - Find your app: `pravenya-github-actions` (Client ID: `e2d49ead-387c-4032-a71b-91c19b72ed27`)
   - Go to **Certificates & secrets**
   - Click **New client secret**
   - Add description: "GitHub Actions Secret"
   - Set expiration (e.g., 1 year)
   - Click **Add**
   - **Copy the secret value immediately** (it won't be shown again!)
   - Update GitHub Secret `AZURE_CLIENT_SECRET` with the new value

**Important Notes:**
- Application passwords are only shown once when created
- Always save the secret value immediately
- Update GitHub Secrets after creating a new password
- The secret value is different from the secret ID (Key ID)
- Make sure you're copying the **Value**, not the **Secret ID**

### Error: Terraform Init Hanging or Timing Out - Backend Storage Access

**Problem:**
Terraform init is hanging or timing out when trying to access the backend storage account.

**Symptoms:**
- `terraform init` runs for 7+ minutes without completing
- Eventually times out or errors
- Error about accessing storage account or container

**Root Cause:**
The service principal doesn't have permissions to access the Azure Storage account used for Terraform state.

**Solution:**

The service principal needs **Storage Blob Data Contributor** role on the storage account to read/write Terraform state files.

#### Option 1: Grant Storage Permissions via Azure CLI

```bash
# Get your service principal Object ID
SP_OBJECT_ID=$(az ad sp show --id <SERVICE_PRINCIPAL_CLIENT_ID> --query id -o tsv)

# Grant Storage Blob Data Contributor role on the storage account
az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-pravenya-terraform-state/providers/Microsoft.Storage/storageAccounts/tfstatepravenya74f45b"
```

Replace:
- `<SERVICE_PRINCIPAL_CLIENT_ID>` with your service principal Client ID (e.g., `e2d49ead-387c-4032-a71b-91c19b72ed27`)
- `<SUBSCRIPTION_ID>` with your subscription ID (e.g., `b99aacbc-2d02-49b1-9d5d-561ba9909ff5`)

#### Option 2: Grant Storage Permissions via Azure Portal

1. Go to Azure Portal → **Storage accounts**
2. Find your storage account: `tfstatepravenya74f45b`
3. Go to **Access control (IAM)**
4. Click **Add** → **Add role assignment**
5. Select role: **Storage Blob Data Contributor**
6. Assign access to: **User, group, or service principal**
7. Search for your service principal: `pravenya-github-actions`
8. Click **Save**

#### Option 3: Use Storage Account Key (Less Secure)

If you can't grant role-based access, you can use the storage account key:

1. Get the storage account key:
   ```bash
   az storage account keys list \
       --resource-group rg-pravenya-terraform-state \
       --account-name tfstatepravenya74f45b \
       --query "[0].value" -o tsv
   ```

2. Add it as a GitHub Secret: `ARM_ACCESS_KEY`

3. Terraform will automatically use this for backend authentication

**Important Notes:**
- Storage Blob Data Contributor role is recommended for security
- Role assignments may take 2-5 minutes to propagate
- The workflow now has a 5-minute timeout for init to prevent hanging
- If init still hangs, check network connectivity and storage account accessibility

## Getting Help

If you encounter other issues:

1. Check the Terraform plan output for detailed error messages
2. Review the GitHub Actions workflow logs
3. Verify all required GitHub Secrets are set correctly
4. Ensure the service principal has the necessary permissions

