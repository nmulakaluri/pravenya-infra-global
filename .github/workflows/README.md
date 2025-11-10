# GitHub Actions Workflows

This directory contains GitHub Actions workflows for deploying infrastructure.

## Workflows

### `deploy.yml` - Non-Prod to Prod Deployment Pipeline

This workflow implements a promotion-based deployment strategy:

1. **Deploy to Non-Production** - Automatically deploys on push to main
2. **Test Non-Production** - Runs validation tests
3. **Deploy to Production** - Requires manual approval or workflow dispatch
4. **Validate Production** - Post-deployment validation

## Setup

### Required GitHub Secrets

Add these secrets to your GitHub repository:

1. **AZURE_CLIENT_ID** - Service Principal Client ID
2. **AZURE_CLIENT_SECRET** - Service Principal Secret
3. **AZURE_SUBSCRIPTION_ID** - Azure Subscription ID
4. **AZURE_TENANT_ID** - Azure AD Tenant ID
5. **AZURE_CREDENTIALS** - Azure credentials JSON (for Azure CLI)

### Required GitHub Environments

Create these environments in your GitHub repository:

1. **nonprod** - Non-Production environment
2. **prod** - Production environment (with protection rules)

### Setting Up Environments

1. Go to your repository → Settings → Environments
2. Create `nonprod` environment
3. Create `prod` environment with:
   - **Required reviewers**: Add team members who must approve
   - **Wait timer**: Optional delay before deployment
   - **Deployment branches**: Restrict to `main` branch only

### Setting Up Azure Service Principal

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "pravenya-github-actions" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth

# Copy the JSON output and add it as AZURE_CREDENTIALS secret
```

## Usage

### Automatic Deployment (Non-Prod)

- Push to `main` branch → Automatically deploys to Non-Prod
- Pull requests → Runs plan only (no apply)

### Manual Production Promotion

1. Go to Actions tab
2. Select "Deploy Infrastructure - Non-Prod to Prod"
3. Click "Run workflow"
4. Check "Promote to Production after Non-Prod deployment"
5. Click "Run workflow"

### Workflow Triggers

- **Push to main**: Deploys to Non-Prod, then prompts for Prod approval
- **Pull Request**: Runs plan only (validation)
- **Manual Dispatch**: Full control over deployment

## Workflow Jobs

### 1. deploy-nonprod
- Checks out code
- Initializes Terraform
- Plans and applies to Non-Prod environment
- Saves outputs for reference

### 2. test-nonprod
- Runs validation tests
- Checks resource health
- Validates configuration
- Must pass before Prod deployment

### 3. deploy-prod
- Requires approval (if environment protection enabled)
- Plans and applies to Production
- Saves outputs

### 4. validate-prod
- Post-deployment validation
- Production health checks
- Final verification

## Customization

### Adding Custom Tests

Edit the `test-nonprod` job to add your validation:

```yaml
- name: Run Custom Tests
  run: |
    # Your test commands here
    ./scripts/validate-infrastructure.sh
```

### Modifying Deployment Logic

Edit the `if` conditions in `deploy-prod` job to change when production deploys:

```yaml
if: |
  github.event_name == 'workflow_dispatch' ||
  (github.event_name == 'push' && needs.test-nonprod.result == 'success')
```

## Best Practices

1. **Always review plans** before applying to production
2. **Use environment protection** for production deployments
3. **Test thoroughly** in Non-Prod before promoting
4. **Monitor deployments** and set up alerts
5. **Keep secrets secure** and rotate regularly

## Troubleshooting

### Workflow Fails at Init

- Check that backend storage account exists
- Verify ARM credentials are correct
- Ensure service principal has proper permissions

### Production Deployment Blocked

- Check environment protection rules
- Verify required reviewers are available
- Check if wait timer is active

### Tests Fail

- Review test output in Actions logs
- Check Azure resource status
- Verify test scripts are correct

