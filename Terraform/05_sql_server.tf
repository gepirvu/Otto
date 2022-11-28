resource "random_string" "sql_password" {
    length = 16
    special = true
}

#Create SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "${var.prefix}-sqlserver-${random_string.postfix.result}"
  resource_group_name          = data.azurerm_resource_group.rg_name.name
  location                     = data.azurerm_resource_group.rg_name.location
  version                      = "12.0"
  administrator_login          = "adminuser${var.prefix}"
  administrator_login_password = random_string.sql_password.result
  minimum_tls_version = "1.2"
  public_network_access_enabled = true
  lifecycle {
   ignore_changes = [administrator_login_password, tags]
 }

}

#Add network rules
resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
  name = "sql_vnet_rule"
  server_id = azurerm_mssql_server.sql_server.id
  subnet_id = azurerm_subnet.backend_subnet.id
  
}

resource "azurerm_mssql_firewall_rule" "example" {
  name             = "FirewallRuleSQL"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "85.216.51.235" #INFOMOTION George, use yours
  end_ip_address   = "85.216.51.235"
}


resource "azurerm_mssql_database" "sql_db" {
    name = "${var.prefix}-sqldb" 
    server_id = azurerm_mssql_server.sql_server.id
    collation = "Latin1_General_CI_AS"
    max_size_gb = 2
    sku_name = "Basic"
    zone_redundant = false

      lifecycle {
  ignore_changes = [ tags  ]
}
}
