data "azapi_resource" "rg" {
  name = var.resource_group_name
  type = "Microsoft.Resources/resourceGroups@2024-11-01"
}

# In ordinary usage, the lock attribute value would be set to var.lock.
module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.5.0"

  enable_telemetry = var.enable_telemetry
  lock = {
    kind = var.lock.kind
    name = coalesce(var.lock.name, "lock-${var.lock.kind}")
  }
  role_assignment_definition_scope = azapi_resource.app_service_certificate_order.id
  role_assignments = { for key, assignment in var.role_assignments : key => {
    principal_id                           = assignment.principal_id
    condition                              = assignment.condition
    condition_version                      = assignment.condition_version
    delegated_managed_identity_resource_id = assignment.delegated_managed_identity_resource_id
    principal_type                         = assignment.principal_type
    role_definition_id_or_name             = assignment.role_definition_id_or_name
    skip_service_principal_aad_check       = assignment.skip_service_principal_aad_check
    }
  }
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = module.avm_interfaces.lock_azapi.name != null ? module.avm_interfaces.lock_azapi.name : coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = data.azapi_resource.rg.id
  type      = module.avm_interfaces.lock_azapi.type
  body      = module.avm_interfaces.lock_azapi.body

  depends_on = [
    azapi_resource.app_service_certificate_order,
  ]
}

resource "azapi_resource" "role_assignments" {
  for_each = module.avm_interfaces.role_assignments_azapi

  name      = each.value.name
  parent_id = data.azapi_resource.rg.id
  type      = each.value.type
  body      = each.value.body

  depends_on = [
    azapi_resource.app_service_certificate_order,
  ]
}

resource "azapi_resource" "app_service_certificate_order" {
  location  = var.location
  name      = var.name
  parent_id = data.azapi_resource.rg.id
  type      = "Microsoft.CertificateRegistration/certificateOrders@2021-01-01"
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
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_null_property   = true
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["*"]
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    precondition {
      condition     = var.csr == null || var.csr == "" || var.distinguished_name == null || var.distinguished_name == ""
      error_message = "`csr` and `distinguished_name` cannot be set together."
    }
  }
}

resource "azapi_resource" "app_service_certificate_order_key_vault_store" {
  for_each = var.certificate_order_key_vault_stores

  name      = each.value.name
  parent_id = azapi_resource.app_service_certificate_order.id
  type      = "Microsoft.CertificateRegistration/certificateOrders/certificates@2021-01-01"
  body = {
    properties = {
      keyVaultId         = each.value.key_vault_id
      keyVaultSecretName = each.value.key_vault_secret_name
    }
  }
  create_headers       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_casing        = true
  ignore_null_property = true
  read_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  tags                 = each.value.tags
  update_headers       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
