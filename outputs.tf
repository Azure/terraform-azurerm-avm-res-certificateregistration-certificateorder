output "resource" {
  description = "The resource of app service certificate order"
  value       = azapi_resource.app_service_certificate_order
}

output "resource_id" {
  description = "The resource ID of app service certificate order"
  value       = azapi_resource.app_service_certificate_order.id
}

output "resource_in_azurerm_schema" {
  description = "The resource of app service certificate order in azurerm schema"
  value       = local.azurerm_resource_body
}
