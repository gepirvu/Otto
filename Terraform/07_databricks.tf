data "databricks_spark_version" "latest_lts" {
  long_term_support = true

  depends_on = [
    azurerm_databricks_workspace.adb_workspace
  ]
}

data "databricks_node_type" "smallest" {
  local_disk = true
  depends_on = [azurerm_databricks_workspace.adb_workspace]
}



resource "azurerm_databricks_workspace" "adb_workspace" {
  location                 = data.azurerm_resource_group.rg_name.location
  resource_group_name      = data.azurerm_resource_group.rg_name.name
  name                          = "${var.prefix}-adb-${random_string.postfix.result}"
  sku                           = "premium"
  

custom_parameters {
    no_public_ip                                         = false
    virtual_network_id                                   = azurerm_virtual_network.vnet_sow.id
    public_subnet_name                                   = azurerm_subnet.adbpub.name
    private_subnet_name                                  = azurerm_subnet.abdprv.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.nsg_associationpub.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.nsg_associationprv.id
  }


  depends_on = [
    azurerm_subnet_network_security_group_association.nsg_associationpub,
    azurerm_subnet_network_security_group_association.nsg_associationprv
  ]

}

/*
resource "databricks_user" "admin_user" {
  user_name = "gpirvu@infomotion.de"
   depends_on = [azurerm_databricks_workspace.adb_workspace]
}

resource "databricks_user_role" "account_admin" {
  user_id = databricks_user.admin_user.id
  role    = "account_admin"
   depends_on = [azurerm_databricks_workspace.adb_workspace]
}
*/

resource "databricks_cluster" "shared_autoscaling" {
  cluster_name            = "adbcluster${var.usecase_name}"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = "Standard_DS3_v2"
  autotermination_minutes = 20
  autoscale {
    min_workers = 2
    max_workers = 5
  }

 depends_on = [azurerm_databricks_workspace.adb_workspace]
}


