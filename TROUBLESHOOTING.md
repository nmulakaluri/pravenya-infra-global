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

## Getting Help

If you encounter other issues:

1. Check the Terraform plan output for detailed error messages
2. Review the GitHub Actions workflow logs
3. Verify all required GitHub Secrets are set correctly
4. Ensure the service principal has the necessary permissions

