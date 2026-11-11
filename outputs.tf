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
  value = {
    id                  = azapi_resource.app_service_certificate_order.id
    name                = azapi_resource.app_service_certificate_order.name
    resource_group_name = data.azapi_resource.rg.name
    auto_renew          = azapi_resource.app_service_certificate_order.body.properties.autoRenew
    csr                 = try(azapi_resource.app_service_certificate_order.body.properties.csr, null)
    distinguished_name  = try(azapi_resource.app_service_certificate_order.body.properties.distinguishedName, null)
    key_size            = azapi_resource.app_service_certificate_order.body.properties.keySize
    product_type        = azapi_resource.app_service_certificate_order.body.properties.productType
    validity_in_years   = azapi_resource.app_service_certificate_order.body.properties.validityInYears
    tags                = azapi_resource.app_service_certificate_order.tags
  }
}
