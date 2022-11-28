# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Azure Machine Learning Workspace with Private Link

resource "azurerm_machine_learning_workspace" "aml_ws" {
  name                    = "${var.prefix}-ws-${random_string.postfix.result}"
  friendly_name           = var.workspace_display_name
  location                = data.azurerm_resource_group.rg_name.location
  resource_group_name     = data.azurerm_resource_group.rg_name.name
  application_insights_id = azurerm_application_insights.aml_ai.id
  key_vault_id            = azurerm_key_vault.aml_kv.id
  storage_account_id      = azurerm_storage_account.aml_sa.id
  container_registry_id   = azurerm_container_registry.aml_acr.id

  identity {
    type = "SystemAssigned"
  }

        lifecycle {
  ignore_changes = [ tags  ]
}
}

# Create Compute Resources in AML

resource "null_resource" "compute_resouces" {
  provisioner "local-exec" {
    command="az ml computetarget create amlcompute --max-nodes 4 --min-nodes 0 --name cpucluster --vm-size Standard_DS2_v2 --idle-seconds-before-scaledown 600 --assign-identity [system] --vnet-name ${azurerm_subnet.backend_subnet.virtual_network_name} --subnet-name ${azurerm_subnet.backend_subnet.name} --vnet-resourcegroup-name ${azurerm_subnet.backend_subnet.resource_group_name} --resource-group ${azurerm_machine_learning_workspace.aml_ws.resource_group_name} --workspace-name ${azurerm_machine_learning_workspace.aml_ws.name}"
  }

  provisioner "local-exec" {
    command="az ml computetarget create computeinstance --name ci${random_string.postfix.result}test --vm-size Standard_DS2_v2 --vnet-name ${azurerm_subnet.backend_subnet.virtual_network_name} --subnet-name ${azurerm_subnet.backend_subnet.name} --vnet-resourcegroup-name ${azurerm_subnet.backend_subnet.resource_group_name} --resource-group ${azurerm_machine_learning_workspace.aml_ws.resource_group_name} --workspace-name ${azurerm_machine_learning_workspace.aml_ws.name}"
  }
 
  depends_on = [azurerm_machine_learning_workspace.aml_ws, databricks_cluster.shared_autoscaling ]
}

# DNS Zones

resource "azurerm_private_dns_zone" "ws_zone_api" {
  name                = "privatelink.api.azureml.ms"
  resource_group_name = data.azurerm_resource_group.rg_name.name
    lifecycle {
  ignore_changes = [ tags  ]
}
}

resource "azurerm_private_dns_zone" "ws_zone_notebooks" {
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = data.azurerm_resource_group.rg_name.name
    lifecycle {
  ignore_changes = [ tags  ]
}
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_api_link" {
  name                  = "${random_string.postfix.result}_link_api"
  resource_group_name   = data.azurerm_resource_group.rg_name.name
  private_dns_zone_name = azurerm_private_dns_zone.ws_zone_api.name
  virtual_network_id    = azurerm_virtual_network.vnet_sow.id
    lifecycle {
  ignore_changes = [ tags  ]
}
}

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_notebooks_link" {
  name                  = "${random_string.postfix.result}_link_notebooks"
  resource_group_name   = data.azurerm_resource_group.rg_name.name
  private_dns_zone_name = azurerm_private_dns_zone.ws_zone_notebooks.name
  virtual_network_id    = azurerm_virtual_network.vnet_sow.id
    lifecycle {
  ignore_changes = [ tags  ]
}
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "ws_pe" {
  name                = "${var.prefix}-ws-pe-${random_string.postfix.result}"
  location            = data.azurerm_resource_group.rg_name.location
  resource_group_name = data.azurerm_resource_group.rg_name.name
  subnet_id           = azurerm_subnet.backend_subnet.id
  lifecycle {
  ignore_changes = [ tags  ]
}


  private_service_connection {
    name                           = "${var.prefix}-ws-psc-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_machine_learning_workspace.aml_ws.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-ws"
    private_dns_zone_ids = [azurerm_private_dns_zone.ws_zone_api.id, azurerm_private_dns_zone.ws_zone_notebooks.id]
  }

  # Add Private Link after we configured the workspace and attached AKS
  depends_on = [null_resource.compute_resouces]
}


