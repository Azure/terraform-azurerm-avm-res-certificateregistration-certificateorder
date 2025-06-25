data "azapi_resource" "rg" {
  name = var.resource_group_name
  type = "Microsoft.Resources/resourceGroups@2024-11-01"
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.app_service_certificate_order.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.app_service_certificate_order.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azapi_resource" "app_service_certificate_order" {
  type      = "Microsoft.CertificateRegistration/certificateOrders@2021-01-01"
  parent_id = data.azapi_resource.rg.id
  name      = var.name
  location  = var.app_service_certificate_order_location
  tags      = var.tags

  body = {
    properties = { for k, v in {
      autoRenew         = var.auto_renew
      csr               = var.csr
      distinguishedName = var.distinguished_name
      keySize           = var.key_size
      productType       = var.product_type == "Standard" ? "StandardDomainValidatedSsl" : "StandardDomainValidatedWildCardSsl"
      validityInYears   = var.validity_in_years
      } : k => v if v != null && v != ""
    }
  }

  lifecycle {
    precondition {
      condition     = var.csr == null || var.csr == "" || var.distinguished_name == null || var.distinguished_name == ""
      error_message = "`csr` and `distinguished_name` cannot be set together."
    }
  }

  response_export_values = ["id", "name", "location", "tags", "properties.autoRenew", "properties.csr", "properties.distinguishedName", "properties.keySize", "properties.productType", "properties.validityInYears"]

  create_headers = { "User-Agent" : local.avm_azapi_header }
  delete_headers = { "User-Agent" : local.avm_azapi_header }
  read_headers   = { "User-Agent" : local.avm_azapi_header }
  update_headers = { "User-Agent" : local.avm_azapi_header }
}

resource "azapi_resource" "app_service_certificate_order_key_vault_store" {
  count = var.certificate_order_key_vault_store != null ? 1 : 0

  type      = "Microsoft.CertificateRegistration/certificateOrders/certificates@2021-01-01"
  parent_id = azapi_resource.app_service_certificate_order.id
  name      = var.certificate_order_key_vault_store.name
  tags      = var.certificate_order_key_vault_store.tags

  body = {
    properties = {
      keyVaultId         = var.certificate_order_key_vault_store.key_vault_id
      keyVaultSecretName = var.certificate_order_key_vault_store.key_vault_secret_name
    }
  }

  ignore_casing = true

  create_headers = { "User-Agent" : local.avm_azapi_header }
  delete_headers = { "User-Agent" : local.avm_azapi_header }
  read_headers   = { "User-Agent" : local.avm_azapi_header }
  update_headers = { "User-Agent" : local.avm_azapi_header }
}
