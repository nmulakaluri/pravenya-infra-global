# This file is kept for organizational purposes
# Management groups are defined in main.tf

# Output management group IDs for reference
output "management_group_ids" {
  description = "IDs of management groups"
  value = {
    root    = azurerm_management_group.root.id
    nonprod = azurerm_management_group.nonprod.id
    prod    = azurerm_management_group.prod.id
  }
}

