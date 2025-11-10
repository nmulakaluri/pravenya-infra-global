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

