locals {
  azurerm_resource_body = {
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
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
