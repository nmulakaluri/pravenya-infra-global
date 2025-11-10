# Important Note About This Workflow

This workflow (`deploy.yml`) is designed for repositories that have separate non-prod and prod environments.

## For `infra-global` Repository

This repository manages **global** infrastructure (management groups, Entra ID, policies) that applies to all environments. The workflow here is a template that you can adapt.

**Recommended approach for infra-global:**
- Deploy directly to production (global resources affect all environments)
- Or create a simple workflow that validates and applies changes

## For `infra-nonprod` and `infra-prod` Repositories

This workflow structure is **perfect** for:
- `infra-nonprod` - Deploy to non-prod first
- `infra-prod` - Promote to prod after testing

**To use this workflow in those repos:**
1. Copy `.github/workflows/deploy.yml` to `infra-nonprod` and `infra-prod`
2. Adjust the working directories as needed
3. Set up the appropriate secrets and environments

## Workflow Structure

The workflow implements:
1. **Deploy to Non-Prod** - Automatic deployment
2. **Test Non-Prod** - Validation tests
3. **Deploy to Prod** - Requires approval
4. **Validate Prod** - Post-deployment checks

This ensures safe, tested deployments with proper approval gates for production.

