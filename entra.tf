# Entra ID Groups
resource "azuread_group" "admins" {
  display_name     = "pravenya-admins"
  security_enabled = true
  description      = "Administrators for Pravenya organization"
}

resource "azuread_group" "devs" {
  display_name     = "pravenya-devs"
  security_enabled = true
  description      = "Developers for Pravenya organization"
}

resource "azuread_group" "viewers" {
  display_name     = "pravenya-viewers"
  security_enabled = true
  description      = "Viewers for Pravenya organization"
}

# App Registration
resource "azuread_application" "pravenya_web" {
  display_name = "pravenya-web"
  description  = "Pravenya Web Application Registration"
  
  web {
    redirect_uris = ["https://pravenya-web.azurestaticapps.net/"]
  }
}

# Service Principal
resource "azuread_service_principal" "pravenya_web" {
  client_id                    = azuread_application.pravenya_web.client_id
  app_role_assignment_required = false
  description                  = "Service principal for Pravenya Web Application"
}

# Service Principal for GitHub Actions
resource "azuread_application" "github_actions" {
  display_name = "pravenya-github-actions"
  description  = "Service Principal for GitHub Actions CI/CD"
}

resource "azuread_service_principal" "github_actions" {
  client_id                    = azuread_application.github_actions.client_id
  app_role_assignment_required = false
  description                  = "Service Principal for GitHub Actions CI/CD"
}

# Create a password/secret for the service principal
resource "azuread_application_password" "github_actions" {
  application_id = azuread_application.github_actions.id
  display_name   = "GitHub Actions Secret"
  
  # Set expiration (optional - 1 year from now)
  end_date = timeadd(timestamp(), "8760h") # 1 year
}

# Assign Contributor role to the service principal
resource "azurerm_role_assignment" "github_actions_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
  description          = "Allow GitHub Actions service principal to manage resources"
}

# Output the object IDs for use in other repositories
output "entra_group_ids" {
  description = "Object IDs of Entra ID groups"
  value = {
    admins  = azuread_group.admins.object_id
    devs    = azuread_group.devs.object_id
    viewers = azuread_group.viewers.object_id
  }
}

output "service_principal_id" {
  description = "Object ID of the Pravenya Web service principal"
  value       = azuread_service_principal.pravenya_web.object_id
}

output "app_registration_client_id" {
  description = "Client ID of the Pravenya Web app registration"
  value       = azuread_application.pravenya_web.client_id
  sensitive   = false
}

# GitHub Actions Service Principal Outputs
output "github_actions_service_principal" {
  description = "GitHub Actions Service Principal details for GitHub Secrets"
  value = {
    client_id     = azuread_application.github_actions.client_id
    client_secret = azuread_application_password.github_actions.value
    tenant_id     = var.tenant_id
    subscription_id = var.subscription_id
  }
  sensitive = true
}

output "github_actions_client_id" {
  description = "GitHub Actions Service Principal Client ID (for AZURE_CLIENT_ID secret)"
  value       = azuread_application.github_actions.client_id
  sensitive   = false
}

output "github_actions_client_secret" {
  description = "GitHub Actions Service Principal Client Secret (for AZURE_CLIENT_SECRET secret)"
  value       = azuread_application_password.github_actions.value
  sensitive   = true
}

