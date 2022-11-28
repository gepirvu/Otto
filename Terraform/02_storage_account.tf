# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Storage Account with VNET binding and Private Endpoint for Blob and File

resource "azurerm_storage_account" "aml_sa" {
  name                     = "${var.prefix}sa${random_string.postfix.result}"
  location                 = data.azurerm_resource_group.rg_name.location
  resource_group_name      = data.azurerm_resource_group.rg_name.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"
  is_hns_enabled = false
  lifecycle {
  ignore_changes = [ tags  ]
}
}

# Virtual Network & Firewall configuration

resource "azurerm_storage_account_network_rules" "firewall_rules" {
  storage_account_id = azurerm_storage_account.aml_sa.id 

  default_action             = "Deny"
  ip_rules                   = [var.ip_range]
  virtual_network_subnet_ids = [azurerm_subnet.backend_subnet.id, azurerm_subnet.frontend_subnet.id, azurerm_subnet.abdprv.id, azurerm_subnet.adbpub.id ]
  bypass                     = ["AzureServices"]

  # Set network policies after Workspace has been created (will create File Share Datastore properly)
  depends_on = [azurerm_machine_learning_workspace.aml_ws]
}

# DNS Zones

resource "azurerm_private_dns_zone" "sa_zone_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg_name.name
    lifecycle {
  ignore_changes = [ tags  ]
}
}

resource "azurerm_private_dns_zone" "sa_zone_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg_name.name
    lifecycle {
  ignore_changes = [ tags  ]
}
}

resource "azurerm_private_dns_zone" "sa_zone_data_lake" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg_name.name
    lifecycle {
  ignore_changes = [ tags  ]
}
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_blob_link" {
  name                  = "${random_string.postfix.result}_link_blob"
  resource_group_name   = data.azurerm_resource_group.rg_name.name
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet_sow.id
    lifecycle {
  ignore_changes = [ tags  ]
}
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_file_link" {
  name                  = "${random_string.postfix.result}_link_file"
  resource_group_name   = data.azurerm_resource_group.rg_name.name
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_file.name
  virtual_network_id    = azurerm_virtual_network.vnet_sow.id
    lifecycle {
  ignore_changes = [ tags  ]
}
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_dfs_link" {
  name                  = "${random_string.postfix.result}_link_dfs"
  resource_group_name   = data.azurerm_resource_group.rg_name.name
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_data_lake.name
  virtual_network_id    = azurerm_virtual_network.vnet_sow.id
    lifecycle {
  ignore_changes = [ tags  ]
}
}


# Private Endpoint configuration

resource "azurerm_private_endpoint" "sa_pe_blob" {
  name                = "${var.prefix}-sa-pe-blob-${random_string.postfix.result}"
  location                 = data.azurerm_resource_group.rg_name.location
  resource_group_name      = data.azurerm_resource_group.rg_name.name
  subnet_id           = azurerm_subnet.backend_subnet.id
  lifecycle {
  ignore_changes = [ tags  ]
}
  private_service_connection {
    name                           = "${var.prefix}-sa-psc-blob-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_storage_account.aml_sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_zone_blob.id]
  }
}

resource "azurerm_private_endpoint" "sa_pe_file" {
  name                = "${var.prefix}-sa-pe-file-${random_string.postfix.result}"
  location                 = data.azurerm_resource_group.rg_name.location
  resource_group_name      = data.azurerm_resource_group.rg_name.name
  subnet_id           = azurerm_subnet.backend_subnet.id
  lifecycle {
  ignore_changes = [ tags  ]
}
  private_service_connection {
    name                           = "${var.prefix}-sa-psc-file-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_storage_account.aml_sa.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-file"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_zone_file.id]
  }
}



resource "azurerm_private_endpoint" "sa_pe_data_lake" {
  name                = "${var.prefix}-sa-pe-dfs-${random_string.postfix.result}"
  location                 = data.azurerm_resource_group.rg_name.location
  resource_group_name      = data.azurerm_resource_group.rg_name.name
  subnet_id           = azurerm_subnet.backend_subnet.id
  lifecycle {
  ignore_changes = [ tags  ]
}
  private_service_connection {
    name                           = "${var.prefix}-sa-psc-dfs-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_storage_account.aml_sa.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-dfs"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_zone_data_lake.id]
  }
}
