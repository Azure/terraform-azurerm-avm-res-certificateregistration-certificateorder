## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.5"
}

data "azurerm_client_config" "current" {}

data "azuread_service_principal" "cert_spn" {
  display_name = "Microsoft.Azure.CertificateRegistration"
}

data "azuread_service_principal" "app_service_spn" {
  display_name = "Microsoft Azure App Service"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

resource "random_string" "name_suffix" {
  length  = 5
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = "avm-res-app-service-certificate-order-${random_string.name_suffix.result}"
  type     = "Microsoft.Resources/resourceGroups@2024-11-01"
}

resource "azapi_resource" "key_vault" {
  type      = "Microsoft.KeyVault/vaults@2021-10-01"
  parent_id = azapi_resource.resource_group.id
  name      = "kv-${random_string.name_suffix.id}"
  location  = azapi_resource.resource_group.location
  body = {
    properties = {
      accessPolicies = [
        {
          objectId = data.azurerm_client_config.current.object_id
          permissions = {
            certificates = [
              "Create",
              "Delete",
              "Get",
              "Purge",
              "Import",
              "List"
            ]
            keys = [
            ]
            secrets = [
              "Delete",
              "Get",
              "Purge",
              "Set",
              "List"
            ]
            storage = [
            ]
          }
          tenantId = data.azurerm_client_config.current.tenant_id
        },
        {
          objectId = data.azuread_service_principal.app_service_spn.object_id
          permissions = {
            certificates = [
              "Create",
              "Delete",
              "Get",
              "Purge",
              "Import",
              "List"
            ]
            keys = [
            ]
            secrets = [
              "Delete",
              "Get",
              "Purge",
              "Set",
              "List"
            ]
            storage = [
            ]
          }
          tenantId = data.azurerm_client_config.current.tenant_id
        },
        {
          objectId = data.azuread_service_principal.cert_spn.object_id
          permissions = {
            certificates = [
              "Create",
              "Delete",
              "Get",
              "Purge",
              "Import",
              "List"
            ]
            keys = [
            ]
            secrets = [
              "Delete",
              "Get",
              "Purge",
              "Set",
              "List"
            ]
            storage = [
            ]
          }
          tenantId = data.azurerm_client_config.current.tenant_id
        }
      ]
      createMode                   = "default"
      enableRbacAuthorization      = false
      enableSoftDelete             = false
      enabledForDeployment         = false
      enabledForDiskEncryption     = false
      enabledForTemplateDeployment = false
      publicNetworkAccess          = "Enabled"
      sku = {
        family = "A"
        name   = "standard"
      }
      softDeleteRetentionInDays = 7
      tenantId                  = data.azurerm_client_config.current.tenant_id
    }
  }
}

resource "azapi_resource" "dns_zone" {
  type      = "Microsoft.Network/dnsZones@2018-05-01"
  parent_id = azapi_resource.resource_group.id
  name      = "dnszone${random_string.name_suffix.id}.com"
  location  = "global"
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"

  # source              = "Azure/avm-res-app-service-certificate-order"
  location                               = azapi_resource.resource_group.location
  resource_group_name                    = azapi_resource.resource_group.name
  name                                   = "app-service-certificate-order-${random_string.name_suffix.id}"
  app_service_certificate_order_location = "global"
  auto_renew                             = false
  distinguished_name                     = "CN=${azapi_resource.dns_zone.name}"
  key_size                               = 2048
  product_type                           = "Standard"
  validity_in_years                      = 1

  tags = {
    environment = "test"
  }

  certificate_order_key_vault_store = {
    name                  = "store1-${random_string.name_suffix.id}"
    key_vault_id          = azapi_resource.key_vault.id
    key_vault_secret_name = "kvsec${random_string.name_suffix.id}"

    tags = {
      env = "Test"
    }
  }

  enable_telemetry = var.enable_telemetry # see variables.tf

  depends_on = [azapi_resource.resource_group]
}
