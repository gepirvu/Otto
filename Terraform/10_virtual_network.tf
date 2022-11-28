# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Virtual Network definition

resource "azurerm_virtual_network" "vnet_sow" {
  name                = "${var.prefix}-vnet-${random_string.postfix.result}"
  address_space       = ["100.68.194.0/24"]
  location            = data.azurerm_resource_group.rg_name.location
  resource_group_name = data.azurerm_resource_group.rg_name.name
  lifecycle {
  ignore_changes = [ tags  ]
}
}

resource "azurerm_subnet" "backend_subnet" {
  name                 = "${var.prefix}-backend_subnet-${random_string.postfix.result}"
  resource_group_name  = data.azurerm_resource_group.rg_name.name
  virtual_network_name = azurerm_virtual_network.vnet_sow.name
  address_prefixes     = ["100.68.194.128/27"]
  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql"]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_subnet" "frontend_subnet" {
  name                 = "${var.prefix}-frontend_subnet-${random_string.postfix.result}"
  resource_group_name  = data.azurerm_resource_group.rg_name.name
  virtual_network_name = azurerm_virtual_network.vnet_sow.name
  address_prefixes     = ["100.68.194.160/27"]
  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage","Microsoft.Sql"]
  private_endpoint_network_policies_enabled = true
}

resource "azurerm_subnet" "abdprv" {
  name                 = "${var.prefix}-adbprv-${random_string.postfix.result}"
  resource_group_name  = data.azurerm_resource_group.rg_name.name
  virtual_network_name = azurerm_virtual_network.vnet_sow.name
  address_prefixes     = ["100.68.194.192/26"]
  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage","Microsoft.Sql"]

    delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }

}

resource "azurerm_subnet" "adbpub" {
  name                 = "${var.prefix}-adbpub-${random_string.postfix.result}"
  resource_group_name  = data.azurerm_resource_group.rg_name.name
  virtual_network_name = azurerm_virtual_network.vnet_sow.name
  address_prefixes     = ["100.68.194.64/26"]
  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage","Microsoft.Sql"]

    delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}



resource "azurerm_network_security_group" "nsgprv" {
  name                = "${var.prefix}-nsgprv-${random_string.postfix.result}"
  location            = data.azurerm_resource_group.rg_name.location
  resource_group_name = data.azurerm_resource_group.rg_name.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_associationprv" {
      subnet_id = azurerm_subnet.abdprv.id
      network_security_group_id     = azurerm_network_security_group.nsgprv.id
  }


resource "azurerm_network_security_group" "nsgpub" {
  name                = "${var.prefix}-nsgpub-${random_string.postfix.result}"
  location            = data.azurerm_resource_group.rg_name.location
  resource_group_name = data.azurerm_resource_group.rg_name.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_associationpub" {
      subnet_id = azurerm_subnet.adbpub.id
      network_security_group_id    = azurerm_network_security_group.nsgpub.id
  }