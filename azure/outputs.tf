output "cluster_name" {
  value = azurerm_kubernetes_cluster.cloudops_ai.name
}

output "resource_group" {
  value = azurerm_resource_group.cloudops_ai.name
}

output "acr_login_server" {
  value = azurerm_container_registry.cloudops_ai.login_server
}

output "acr_name" {
  value = azurerm_container_registry.cloudops_ai.name
}
