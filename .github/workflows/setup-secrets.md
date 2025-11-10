# Setting Up GitHub Secrets and Environments

## Step 1: Create Azure Service Principal

```bash
# Login to Azure
az login

# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "pravenya-github-actions" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth

# This will output JSON like:
# {
#   "clientId": "...",
#   "clientSecret": "...",
#   "subscriptionId": "...",
#   "tenantId": "..."
# }
```

## Step 2: Add GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret:

### Required Secrets

| Secret Name | Value | Description |
|------------|-------|-------------|
| `AZURE_CLIENT_ID` | From service principal JSON | Client ID |
| `AZURE_CLIENT_SECRET` | From service principal JSON | Client Secret |
| `AZURE_SUBSCRIPTION_ID` | From service principal JSON | Subscription ID |
| `AZURE_TENANT_ID` | From service principal JSON | Tenant ID |
| `AZURE_CREDENTIALS` | Full JSON output | Complete credentials |

### Example: Adding AZURE_CLIENT_ID

1. Name: `AZURE_CLIENT_ID`
2. Secret: `12345678-1234-1234-1234-123456789012`
3. Click **Add secret**

## Step 3: Create GitHub Environments

### Create Non-Prod Environment

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Name: `nonprod`
4. Click **Configure environment**
5. (Optional) Add environment protection rules
6. Click **Save protection rules**

### Create Prod Environment

1. Click **New environment**
2. Name: `prod`
3. Click **Configure environment**
4. **Required reviewers**: Add team members
5. **Wait timer**: Optional (e.g., 5 minutes)
6. **Deployment branches**: Select "Selected branches" → `main`
7. Click **Save protection rules**

## Step 4: Verify Setup

1. Go to **Actions** tab
2. Create a test workflow or push to main
3. Check that secrets are accessible (they won't be visible in logs)
4. Verify environments appear in workflow runs

## Security Best Practices

1. **Rotate secrets regularly** (every 90 days)
2. **Use least privilege** - Only grant necessary permissions
3. **Review access logs** regularly
4. **Use environment protection** for production
5. **Limit who can modify secrets** (repository settings)

## Troubleshooting

### "Secret not found" error
- Verify secret name matches exactly (case-sensitive)
- Check that secrets are added to the correct repository
- Ensure you're using the right branch

### "Environment not found" error
- Verify environment name matches exactly
- Check that environment exists in repository settings
- Ensure environment protection rules allow the workflow

### Authentication failures
- Verify service principal credentials are correct
- Check service principal hasn't been deleted
- Ensure service principal has proper role assignments

