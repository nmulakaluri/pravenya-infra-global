variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "nonprod_subscription_ids" {
  description = "List of subscription IDs to associate with mg-pravenya-nonprod"
  type        = list(string)
  default     = []
}

variable "prod_subscription_ids" {
  description = "List of subscription IDs to associate with mg-pravenya-prod"
  type        = list(string)
  default     = []
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "subscription_id" {
  description = "Azure Subscription ID (for policy assignment)"
  type        = string
  default     = ""
}

