#Create ADF Workspace
resource "azurerm_data_factory" "adf_ws" {
    name = "${var.prefix}-adf-${random_string.postfix.result}"
    location                 = data.azurerm_resource_group.rg_name.location
    resource_group_name      = data.azurerm_resource_group.rg_name.name
    managed_virtual_network_enabled = true
    identity {
      type = "SystemAssigned"
    }
      lifecycle {
  ignore_changes = [ tags  ]
}
  
  }
  
#Create Azure hoster IR
resource "azurerm_data_factory_integration_runtime_azure" "adf-ir-azure" {
  name            = "ADF-IR-Azure"
  data_factory_id = azurerm_data_factory.adf_ws.id
  location        = data.azurerm_resource_group.rg_name.location
  compute_type = "General"
  core_count = 8
  time_to_live_min = 20
  virtual_network_enabled = true
  
}


#Create Linked Services

resource "azurerm_data_factory_linked_service_azure_blob_storage" "adf-ls_blob" {
  name = "LSBlobStorageML"
  data_factory_id = azurerm_data_factory.adf_ws.id
  use_managed_identity = true
  #connection_string = azurerm_storage_account.aml_sa.primary_connection_string
  service_endpoint = azurerm_storage_account.aml_sa.primary_blob_endpoint
  storage_kind = "StorageV2"
  integration_runtime_name = azurerm_data_factory_integration_runtime_azure.adf-ir-azure.name
  depends_on = [
    azurerm_data_factory_integration_runtime_azure.adf-ir-azure
  ]
}

resource "azurerm_data_factory_linked_service_key_vault" "adf-ls_kv" {
  name = "LSKeyVault"
  data_factory_id = azurerm_data_factory.adf_ws.id
  key_vault_id = azurerm_key_vault.aml_kv.id
  #integration_runtime_name = azurerm_data_factory_integration_runtime_azure.adf-ir-azure.name
  depends_on = [
    azurerm_data_factory_integration_runtime_azure.adf-ir-azure
  ]
}


resource "azurerm_data_factory_linked_service_sql_server" "adf-ls-sql" {
  name            = "LSSQLServer"
  data_factory_id = azurerm_data_factory.adf_ws.id
  integration_runtime_name = azurerm_data_factory_integration_runtime_azure.adf-ir-azure.name

  key_vault_connection_string {
    linked_service_name = azurerm_data_factory_linked_service_key_vault.adf-ls_kv.name
    secret_name         = "SQLServerConnectionString"
  }
}



resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "adf-ls_adls" {
  name = "LSDatalakeStorage"
  data_factory_id = azurerm_data_factory.adf_ws.id
  use_managed_identity = true
  #connection_string = azurerm_storage_account.aml_sa.primary_connection_string
  url = azurerm_storage_account.lz_sa.primary_dfs_endpoint
  integration_runtime_name = azurerm_data_factory_integration_runtime_azure.adf-ir-azure.name
  depends_on = [
    azurerm_data_factory_integration_runtime_azure.adf-ir-azure
  ]
}

resource "azurerm_data_factory_linked_service_azure_databricks" "msi_linked" {
  name            = "LSAzureDatabricksMSI"
  data_factory_id = azurerm_data_factory.adf_ws.id
  description     = "ADB Linked Service via MSI"
  adb_domain      = "https://${azurerm_databricks_workspace.adb_workspace.workspace_url}"

  msi_work_space_resource_id = azurerm_databricks_workspace.adb_workspace.id
  existing_cluster_id  = databricks_cluster.shared_autoscaling.cluster_id
  

}