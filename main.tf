terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}

# Management Groups
resource "azurerm_management_group" "root" {
  display_name = "mg-pravenya-root"
  name         = "mg-pravenya-root"
}

resource "azurerm_management_group" "nonprod" {
  display_name               = "mg-pravenya-nonprod"
  name                       = "mg-pravenya-nonprod"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "prod" {
  display_name               = "mg-pravenya-prod"
  name                       = "mg-pravenya-prod"
  parent_management_group_id = azurerm_management_group.root.id
}

# Associate subscriptions to management groups
resource "azurerm_management_group_subscription_association" "nonprod_subscriptions" {
  for_each             = toset(var.nonprod_subscription_ids)
  management_group_id  = azurerm_management_group.nonprod.id
  subscription_id      = each.value
}

resource "azurerm_management_group_subscription_association" "prod_subscriptions" {
  for_each             = toset(var.prod_subscription_ids)
  management_group_id  = azurerm_management_group.prod.id
  subscription_id      = each.value
}

