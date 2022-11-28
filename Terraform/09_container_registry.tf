# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Azure Container Registry (no VNET binding and/or Private Link)

resource "azurerm_container_registry" "aml_acr" {

  name                     = "${var.prefix}acr${random_string.postfix.result}"
  resource_group_name      = data.azurerm_resource_group.rg_name.name
  location                 = data.azurerm_resource_group.rg_name.location
  sku                      = "Standard"
  admin_enabled            = true

    lifecycle {
  ignore_changes = [ tags  ]
}
}