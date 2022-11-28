# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Application Insights for Azure Machine Learning (no Private Link/VNET integration)

resource "azurerm_application_insights" "aml_ai" {

  name                = "${var.prefix}-ai-${random_string.postfix.result}"
  location            = data.azurerm_resource_group.rg_name.location
  resource_group_name = data.azurerm_resource_group.rg_name.name
  application_type    = "web"

    lifecycle {
  ignore_changes = [ tags  ]
}
}