# Infrastructure Global - Terraform Configuration

This repository contains the global governance and identity configuration for the Pravenya organization using Terraform.

## Purpose

This repository manages:
- **Management Groups**: Organizational hierarchy (mg-pravenya-root, mg-pravenya-nonprod, mg-pravenya-prod)
- **Entra ID (Azure AD)**: Security groups, app registrations, and service principals
- **Azure Policies**: Custom policies for resource governance
- **Role Assignments**: Access control at management group level

## Repository Structure

```
infra-global/
├── main.tf                  # Management groups and subscription associations
├── providers.tf             # Azure and Azure AD provider configurations
├── variables.tf              # Input variables
├── entra.tf                 # Entra ID groups, app registrations, service principals
├── policies.tf               # Policy definitions and assignments
├── management_groups.tf      # Management group outputs
├── role_assignments.tf       # Role assignments at management group level
├── backend.tf                # Remote state backend configuration
└── README.md                 # This file
```

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** >= 1.0 installed
3. **Required permissions**:
   - Management Group Contributor
   - Global Administrator or User Administrator (for Entra ID)
   - Owner or Contributor on subscriptions

## Required Environment Variables

Set the following environment variables before running Terraform:

```bash
export ARM_CLIENT_ID="<service-principal-client-id>"
export ARM_CLIENT_SECRET="<service-principal-secret>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<azure-ad-tenant-id>"
```

Alternatively, you can use Azure CLI authentication:

```bash
az login
az account set --subscription "<subscription-id>"
```

## Configuration

1. **Create a `terraform.tfvars` file** (not committed to git):

```hcl
tenant_id = "<your-tenant-id>"
nonprod_subscription_ids = [
  "<subscription-id-1>",
  "<subscription-id-2>"
]
prod_subscription_ids = [
  "<subscription-id-3>"
]
location = "East US"
```

2. **Configure the backend** in `backend.tf`:
   - Ensure the storage account `tfstatepravenya` exists in resource group `rg-pravenya-terraform-state`
   - The container `state` should exist in the storage account

## Usage

### Initialize Terraform

```bash
terraform init
```

This will:
- Download required providers (azurerm ~> 3.100, azuread ~> 3.0)
- Configure the remote backend

### Plan Changes

```bash
terraform plan
```

Review the planned changes before applying.

### Apply Configuration

```bash
terraform apply
```

Or with auto-approve:

```bash
terraform apply -auto-approve
```

### Destroy Resources

⚠️ **Warning**: Be extremely careful with destroy operations in production environments.

```bash
terraform destroy
```

## What Gets Created

### Management Groups
- `mg-pravenya-root`: Root management group
- `mg-pravenya-nonprod`: Non-production management group
- `mg-pravenya-prod`: Production management group

### Entra ID Groups
- `pravenya-admins`: Administrators group
- `pravenya-devs`: Developers group
- `pravenya-viewers`: Viewers group

### App Registration
- `pravenya-web`: Application registration with service principal

### Policies
- Custom policy: "Pravenya: Require tags on all resources"
  - Assigned to `mg-pravenya-root`
  - Requires tags: Environment, Project, Owner

## Outputs

After applying, Terraform outputs:
- Management group IDs
- Entra ID group object IDs
- Service principal object ID
- App registration client ID

These outputs can be referenced in other repositories using remote state data sources.

## Dependencies

This repository has no dependencies on other Terraform repositories. It should be applied first as it creates foundational resources used by:
- `infra-nonprod`
- `infra-prod`
- `app-pravenya`

## Best Practices

1. **Review changes**: Always run `terraform plan` before `terraform apply`
2. **Use workspaces**: Consider using Terraform workspaces for different environments
3. **Version control**: Commit changes frequently with descriptive messages
4. **PR reviews**: Require peer review for all changes to global infrastructure
5. **State management**: Never commit `.tfstate` files to git
6. **Secrets**: Never commit secrets or sensitive values to git

## Troubleshooting

### Backend Configuration Issues

If you encounter backend errors:
1. Verify the storage account exists: `az storage account show --name tfstatepravenya --resource-group rg-pravenya-terraform-state`
2. Verify the container exists: `az storage container show --name state --account-name tfstatepravenya`

### Permission Issues

If you get permission errors:
1. Verify your Azure CLI login: `az account show`
2. Check your role assignments: `az role assignment list --assignee <your-email>`
3. Ensure you have the required permissions listed in Prerequisites

## CI/CD Integration

This repository is designed to work with GitHub Actions or Azure DevOps pipelines. Example workflow:

1. Run `terraform fmt -check` for formatting validation
2. Run `terraform validate` for syntax validation
3. Run `terraform plan` on pull requests
4. Run `terraform apply` on merge to main (with approval gates)

## Support

For issues or questions, please open an issue in this repository or contact the infrastructure team.

