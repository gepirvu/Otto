# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Key Vault with VNET binding and Private Endpoint
resource "azurerm_key_vault" "aml_kv" {
  
  name                = "${var.prefix}-kv-${random_string.postfix.result}"
  location                 = data.azurerm_resource_group.rg_name.location
  resource_group_name      = data.azurerm_resource_group.rg_name.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  lifecycle {
  ignore_changes = [ tags  ]
}
  network_acls {
    default_action = "Deny"
    ip_rules       = [var.ip_range]
    virtual_network_subnet_ids = [azurerm_subnet.backend_subnet.id, azurerm_subnet.frontend_subnet.id, azurerm_subnet.abdprv.id, azurerm_subnet.adbpub.id ]
    bypass         = "AzureServices"
  }

  
}


# Assign policy service principal
resource "azurerm_key_vault_access_policy" "kv_policies" {
  
  #count = length([data.azurerm_client_config.current.object_id,  azurerm_data_factory.adf_ws.identity[0].principal_id])
  key_vault_id = azurerm_key_vault.aml_kv.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  #object_id = element([data.azurerm_client_config.current.object_id, azurerm_data_factory.adf_ws.identity[0].principal_id], count.index)
  object_id = data.azurerm_client_config.current.object_id
  secret_permissions =  [      "Set",      "Get",      "Delete",      "Purge",      "Recover"  , "List"  ]
}



resource "azurerm_key_vault_access_policy" "kv_policies_adf" {
  
  #count = length([data.azurerm_client_config.current.object_id,  azurerm_data_factory.adf_ws.identity[0].principal_id])
  key_vault_id = azurerm_key_vault.aml_kv.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_data_factory.adf_ws.identity[0].principal_id
  secret_permissions =  [      "Set",      "Get",      "Delete",      "Purge",      "Recover" , "List"   ]
}


#create secrets

resource "azurerm_key_vault_secret" "ks_sql_pass" {
  key_vault_id = azurerm_key_vault.aml_kv.id
  name = "SQLServerPassword"
  value = azurerm_mssql_server.sql_server.administrator_login_password
  depends_on = [
    azurerm_key_vault_access_policy.kv_policies
  ]
}

resource "azurerm_key_vault_secret" "ks_sql_connection_string" {
  key_vault_id = azurerm_key_vault.aml_kv.id
  name = "SQLServerConnectionString"
  value = "Server=tcp:${azurerm_mssql_server.sql_server.name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.sql_db.name};Persist Security Info=False;User ID=${azurerm_mssql_server.sql_server.administrator_login};Password=${azurerm_mssql_server.sql_server.administrator_login_password};MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  depends_on = [
    azurerm_key_vault_access_policy.kv_policies
  ]
}

resource "azurerm_key_vault_secret" "ks_sql_user" {
  key_vault_id = azurerm_key_vault.aml_kv.id
  name = "SQLServerUser"
  value = azurerm_mssql_server.sql_server.administrator_login
  depends_on = [
    azurerm_key_vault_access_policy.kv_policies
  ]
}

resource "azurerm_key_vault_secret" "ks_storage_account_key" {
  key_vault_id = azurerm_key_vault.aml_kv.id
  name = "DataLakeAccountKey"
  value = azurerm_storage_account.lz_sa.primary_access_key
  depends_on = [
    azurerm_key_vault_access_policy.kv_policies, azurerm_storage_account.lz_sa
  ]
}



# DNS Zones

resource "azurerm_private_dns_zone" "kv_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.rg_name.name
  lifecycle {
  ignore_changes = [ tags  ]
}
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "kv_zone_link" {
  name                  = "${random_string.postfix.result}_link_kv"
  resource_group_name   = data.azurerm_resource_group.rg_name.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet_sow.id

    lifecycle {
  ignore_changes = [ tags  ]
}
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${var.prefix}-kv-pe-${random_string.postfix.result}"
  location            = data.azurerm_resource_group.rg_name.location
  resource_group_name = data.azurerm_resource_group.rg_name.name
  subnet_id           = azurerm_subnet.backend_subnet.id
  lifecycle {
  ignore_changes = [ tags  ]
}
  private_service_connection {
    name                           = "${var.prefix}-kv-psc-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_key_vault.aml_kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-kv"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_zone.id]

    
  }
}

