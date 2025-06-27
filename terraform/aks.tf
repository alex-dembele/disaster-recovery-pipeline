# terraform/aks.tf

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-rg"
  location = var.azure_region
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.project_name}-aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.project_name}-aks"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = var.aks_node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_account" "velero_storage" {
  name                     = "velerobackups${substr(sha1(azurerm_resource_group.rg.id), 0, 10)}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
