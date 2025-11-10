# Infrastructure Global - Outputs and Reference

This document contains all outputs and important information from the `infra-global` Terraform deployment.

## 📋 Deployment Information

**Deployment Date:** 2025-11-10 00:04:18
**Terraform State:** Stored in Azure Storage Account `tfstatepravenya74f45b`
**Backend Container:** `state`
**State Key:** `global.terraform.tfstate`

## 🔑 Entra ID Groups

These group Object IDs are required for role assignments in other repositories.

| Group Name | Display Name | Object ID |
|------------|--------------|-----------|
| **Admins** | `pravenya-admins` | `5331c135-72b8-4eb7-8666-0c2771476df6` |
| **Devs** | `pravenya-devs` | `24896802-fb40-49cd-b77d-43875a1a2244` |
| **Viewers** | `pravenya-viewers` | `6db14c37-acdf-43c6-b564-679e69010c70` |

### Usage in Other Repositories

```hcl
# In infra-nonprod/terraform.tfvars
entra_devs_group_id = "24896802-fb40-49cd-b77d-43875a1a2244"

# In infra-prod/terraform.tfvars
entra_admins_group_id = "5331c135-72b8-4eb7-8666-0c2771476df6"
```

## 🏢 Management Groups

Management group IDs for subscription associations and policy assignments.

| Management Group | Display Name | ID |
|-----------------|--------------|-----|
| **Root** | `mg-pravenya-root` | `/providers/Microsoft.Management/managementGroups/mg-pravenya-root` |
| **Non-Prod** | `mg-pravenya-nonprod` | `/providers/Microsoft.Management/managementGroups/mg-pravenya-nonprod` |
| **Prod** | `mg-pravenya-prod` | `/providers/Microsoft.Management/managementGroups/mg-pravenya-prod` |

### Usage

```hcl
# To associate subscriptions with management groups
# Update terraform.tfvars:
nonprod_subscription_ids = [
  "/subscriptions/<nonprod-subscription-id>"
]
prod_subscription_ids = [
  "/subscriptions/<prod-subscription-id>"
]
```

## 🔐 App Registration

Application registration details for the Pravenya Web application.

| Property | Value |
|----------|-------|
| **Display Name** | `pravenya-web` |
| **Client ID** | `4ab92a87-1bed-4522-a0e0-58450c579136` |
| **Service Principal ID** | `67c36069-73d8-49ed-817a-6bd5ee1f95d0` |
| **Redirect URI** | `https://pravenya-web.azurestaticapps.net/` |

### Usage

The Client ID can be used in application code for authentication:
```javascript
const clientId = "4ab92a87-1bed-4522-a0e0-58450c579136";
```

## 📜 Policy

Custom policy for enforcing required tags on all resources.

| Property | Value |
|----------|-------|
| **Policy Name** | `pravenya-require-tags` |
| **Display Name** | `Pravenya: Require tags on all resources` |
| **Assignment Name** | `prv-req-tags` |
| **Scope** | Subscription |
| **Required Tags** | `Environment`, `Project`, `Owner` |
| **Effect** | `Deny` |

### Policy Rule

The policy denies creation of resources that don't have all three required tags:
- `tags['Environment']` - Must exist
- `tags['Project']` - Must exist
- `tags['Owner']` - Must exist

### Example Resource Tags

All resources must include these tags:

```hcl
tags = {
  Environment = "NonProd"  # or "Prod"
  Project     = "Pravenya"
  Owner       = "Infrastructure Team"
}
```

## 🔧 Azure Configuration

### Subscription Details

| Property | Value |
|----------|-------|
| **Subscription ID** | `b99aacbc-2d02-49b1-9d5d-561ba9909ff5` |
| **Subscription Name** | `Azure subscription 1` |
| **Tenant ID** | `2581608f-9d7e-4da3-a33d-499c7f164ac4` |
| **Tenant Domain** | `cloudpravenya.onmicrosoft.com` |

### Backend Storage

| Property | Value |
|----------|-------|
| **Resource Group** | `rg-pravenya-terraform-state` |
| **Storage Account** | `tfstatepravenya74f45b` |
| **Container** | `state` |
| **State Key** | `global.terraform.tfstate` |

## 📝 Terraform Outputs

Run `terraform output` to get current values:

```bash
cd infra-global
terraform output
```

### Output Structure

```hcl
app_registration_client_id = "4ab92a87-1bed-4522-a0e0-58450c579136"

entra_group_ids = {
  "admins"  = "5331c135-72b8-4eb7-8666-0c2771476df6"
  "devs"    = "24896802-fb40-49cd-b77d-43875a1a2244"
  "viewers" = "6db14c37-acdf-43c6-b564-679e69010c70"
}

management_group_ids = {
  "nonprod" = "/providers/Microsoft.Management/managementGroups/mg-pravenya-nonprod"
  "prod"    = "/providers/Microsoft.Management/managementGroups/mg-pravenya-prod"
  "root"    = "/providers/Microsoft.Management/managementGroups/mg-pravenya-root"
}

service_principal_id = "67c36069-73d8-49ed-817a-6bd5ee1f95d0"
```

## 🔗 Integration with Other Repositories

### infra-nonprod

Required variables:
```hcl
entra_devs_group_id = "24896802-fb40-49cd-b77d-43875a1a2244"
```

### infra-prod

Required variables:
```hcl
entra_admins_group_id = "5331c135-72b8-4eb7-8666-0c2771476df6"
```

### app-pravenya

Can reference outputs using remote state:
```hcl
data "terraform_remote_state" "global" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-pravenya-terraform-state"
    storage_account_name = "tfstatepravenya74f45b"
    container_name       = "state"
    key                  = "global.terraform.tfstate"
  }
}

# Use outputs
locals {
  admins_group_id = data.terraform_remote_state.global.outputs.entra_group_ids.admins
  devs_group_id   = data.terraform_remote_state.global.outputs.entra_group_ids.devs
}
```

## 🔄 Updating This Document

To update this document with latest outputs:

```bash
cd infra-global
terraform output -json > outputs.json
# Then update this file with the new values
```

## 📞 Support

For issues or questions:
- Check the main [README.md](README.md)
- Review [SETUP.md](SETUP.md) for setup instructions
- See [QUICKSTART.md](QUICKSTART.md) for quick reference

---

**Last Updated:** 2025-11-10 00:04:18
**Terraform Version:** 1.5.7
**Provider Versions:**
- azurerm: ~> 3.100
- azuread: ~> 3.0

