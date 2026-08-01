terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "cloudops_ai" {
  name     = var.rg_name
  location = var.location
}

# Container registry — holds whatever app image the pipeline builds
# (source repo/HF space is passed in at build time, not baked in here)
resource "azurerm_container_registry" "cloudops_ai" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.cloudops_ai.name
  location            = azurerm_resource_group.cloudops_ai.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "cloudops_ai" {
  name                = var.aks_name
  location            = azurerm_resource_group.cloudops_ai.location
  resource_group_name = azurerm_resource_group.cloudops_ai.name
  dns_prefix          = "cloudopsai"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  # Azure enables this by default on new clusters now; declaring it
  # explicitly avoids Terraform trying to "disable" it on refresh.
  oidc_issuer_enabled = true

  tags = {
    project = "cloudops-ai"
    purpose = "aiops-demo-and-az-cert-prep"
  }
}

# Grant AKS permission to pull from ACR (managed identity, no passwords)
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.cloudops_ai.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.cloudops_ai.kubelet_identity[0].object_id
}
