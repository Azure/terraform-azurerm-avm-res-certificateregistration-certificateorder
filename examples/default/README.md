<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the App Service Certificate Order.

```hcl
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
  location  = azapi_resource.resource_group.location
  name      = "kv-${random_string.name_suffix.id}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.KeyVault/vaults@2021-10-01"
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
  location  = "global"
  name      = "dnszone${random_string.name_suffix.id}.com"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/dnsZones@2018-05-01"
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"

  app_service_certificate_order_location = "global"
  # source              = "Azure/avm-res-app-service-certificate-order"
  location            = azapi_resource.resource_group.location
  name                = "app-service-certificate-order-${random_string.name_suffix.id}"
  resource_group_name = azapi_resource.resource_group.name
  auto_renew          = false
  certificate_order_key_vault_store = {
    name                  = "store1-${random_string.name_suffix.id}"
    key_vault_id          = azapi_resource.key_vault.id
    key_vault_secret_name = "kvsec${random_string.name_suffix.id}"

    tags = {
      env = "Test"
    }
  }
  distinguished_name = "CN=${azapi_resource.dns_zone.name}"
  enable_telemetry   = var.enable_telemetry # see variables.tf
  key_size           = 2048
  product_type       = "Standard"
  tags = {
    environment = "test"
  }
  validity_in_years = 1

  depends_on = [azapi_resource.resource_group]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.11)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.29)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.7)

## Resources

The following resources are used by this module:

- [azapi_resource.dns_zone](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.key_vault](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.resource_group](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_string.name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [azuread_service_principal.app_service_spn](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) (data source)
- [azuread_service_principal.cert_spn](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `false`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: ~> 0.5

### <a name="module_test"></a> [test](#module\_test)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->