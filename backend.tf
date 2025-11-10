terraform {
  backend "azurerm" {
    resource_group_name  = "rg-pravenya-terraform-state"
    storage_account_name = "tfstatepravenya74f45b"
    container_name       = "state"
    key                  = "global.terraform.tfstate"
  }
}

