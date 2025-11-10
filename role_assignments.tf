# Role assignments at management group level can be added here
# Example: Assign Contributor role to pravenya-admins at mg-pravenya-prod

# Note: Role assignments require the principal to exist first
# These should reference outputs from entra.tf

# Example structure (uncomment and configure as needed):
# data "azuread_group" "admins" {
#   display_name = "pravenya-admins"
# }
#
# resource "azurerm_role_assignment" "admins_mg_prod" {
#   scope                = azurerm_management_group.prod.id
#   role_definition_name = "Contributor"
#   principal_id         = data.azuread_group.admins.object_id
# }

