# Policy Definition: Require tags on all resources
resource "azurerm_policy_definition" "require_tags" {
  name         = "pravenya-require-tags"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Pravenya: Require tags on all resources"
  description  = "This policy requires that all resources have required tags: Environment, Project, Owner"

  metadata = jsonencode({
    category = "Tags"
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field    = "tags['Environment']"
          exists   = false
        },
        {
          field    = "tags['Project']"
          exists   = false
        },
        {
          field    = "tags['Owner']"
          exists   = false
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

# Policy Assignment: Assign to subscription
# Note: Subscription-level policy definitions can be assigned to subscriptions
# For management group assignment, the policy definition must be created at management group level
resource "azurerm_subscription_policy_assignment" "require_tags" {
  count                = var.subscription_id != "" ? 1 : 0
  name                 = "prv-req-tags"
  policy_definition_id = azurerm_policy_definition.require_tags.id
  subscription_id      = "/subscriptions/${var.subscription_id}"
  display_name         = "Pravenya: Require tags on all resources"
  description          = "Assigns the require tags policy to the subscription"
}

