# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Storage Account with VNET binding and Private Endpoint for Blob and File

resource "azurerm_storage_account" "lz_sa" {
  name                     = "${var.prefix}adls${random_string.postfix.result}"
  location                 = data.azurerm_resource_group.rg_name.location
  resource_group_name      = data.azurerm_resource_group.rg_name.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"
  is_hns_enabled = true
  lifecycle {
  ignore_changes = [ tags  ]
}
}



resource "azurerm_storage_account_network_rules" "firewall_rules_adls" {
  storage_account_id = azurerm_storage_account.lz_sa.id 

  default_action             = "Deny"
  ip_rules                   = [var.ip_range]
  virtual_network_subnet_ids = [azurerm_subnet.backend_subnet.id, azurerm_subnet.frontend_subnet.id, azurerm_subnet.abdprv.id, azurerm_subnet.adbpub.id ]
  bypass                     = ["AzureServices"]
}



# DNS Zones

resource "azurerm_private_dns_zone" "adls_zone_data_lake" {
  name                = "adlsprivatelink.dfs.core.windows.net"
  resource_group_name = azurerm_storage_account.lz_sa.resource_group_name
    lifecycle {
  ignore_changes = [ tags  ]
}
depends_on = [
  azurerm_storage_account_network_rules.firewall_rules_adls
]
}

# Linking of DNS zones to Virtual Network



resource "azurerm_private_dns_zone_virtual_network_link" "adls_zone_dfs_link" {
  name                  = "${random_string.postfix.result}_link_dfs"
  resource_group_name   = azurerm_storage_account.lz_sa.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.adls_zone_data_lake.name
  virtual_network_id    = azurerm_virtual_network.vnet_sow.id
    lifecycle {
  ignore_changes = [ tags  ]
}
}


# Private Endpoint configuration

resource "azurerm_private_endpoint" "adls_pe_data_lake" {
  name                = "${var.prefix}-sa-pe-adls-${random_string.postfix.result}"
  location            = azurerm_storage_account.lz_sa.location
  resource_group_name = azurerm_storage_account.lz_sa.resource_group_name
  subnet_id           = azurerm_subnet.backend_subnet.id
  lifecycle {
  ignore_changes = [ tags  ]
}
  private_service_connection {
    name                           = "${var.prefix}-sa-psc-dfs-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_storage_account.lz_sa.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-dfs"
    private_dns_zone_ids = [azurerm_private_dns_zone.adls_zone_data_lake.id]
  }
}


# Access to AML
resource "azurerm_role_assignment" "aml2rsg" {
  role_definition_name  = "Storage Blob Data Contributor"
  principal_id          =  azurerm_machine_learning_workspace.aml_ws.identity[0].principal_id
  scope                 = "/subscriptions/${data.azurerm_subscription.subscription.subscription_id}/resourceGroups/${data.azurerm_resource_group.rg_name.name}"
  depends_on = [
    azurerm_machine_learning_workspace.aml_ws
  ]
}


# Access to ADF
resource "azurerm_role_assignment" "adf2rsg" {
  role_definition_name  = "Storage Blob Data Contributor"
  principal_id          = azurerm_data_factory.adf_ws.identity[0].principal_id
  scope                 = "/subscriptions/${data.azurerm_subscription.subscription.subscription_id}/resourceGroups/${data.azurerm_resource_group.rg_name.name}"
  depends_on = [
    azurerm_data_factory.adf_ws
  ]
}


# Service Principal to storage account
#resource "azurerm_role_assignment" "sp2rsg" {
#  role_definition_name  = "Storage Blob Data Contributor"
#  principal_id          = data.azurerm_client_config.current.object_id
#  scope                 = "/subscriptions/${data.azurerm_subscription.subscription.subscription_id}/resourceGroups/${data.azurerm_resource_group.rg_name.name}"

#}



#Create Container and Paths
resource "azurerm_storage_data_lake_gen2_filesystem" "adls_container" {
  name               = "sowcontainer"
  storage_account_id = azurerm_storage_account.lz_sa.id
 #  depends_on = [
 #   azurerm_role_assignment.sp2rsg
 # ]
}

resource "azurerm_storage_data_lake_gen2_path" "Raw_Path" {
  path               = "01_RAW"
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.adls_container.name
  storage_account_id = azurerm_storage_account.lz_sa.id
  resource           = "directory"

}

resource "azurerm_storage_data_lake_gen2_path" "Transformed_Path" {
  path               = "02_TANSFORMATION"
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.adls_container.name
  storage_account_id = azurerm_storage_account.lz_sa.id
  resource           = "directory"

}


resource "azurerm_storage_data_lake_gen2_path" "Serving_Path" {
  path               = "03_SERVING"
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.adls_container.name
  storage_account_id = azurerm_storage_account.lz_sa.id
  resource           = "directory"
}