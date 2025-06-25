<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-certificateregistration-certificateorder

This is an AVM module to deploy App Service Certificate Order in Azure.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.11)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.29)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.7)

## Resources

The following resources are used by this module:

- [azapi_resource.app_service_certificate_order](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.app_service_certificate_order_key_vault_store](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_resource.rg](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) (data source)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_app_service_certificate_order_location"></a> [app\_service\_certificate\_order\_location](#input\_app\_service\_certificate\_order\_location)

Description: (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Currently the only valid value is `global`.

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: (Required) Azure region where the resource should be deployed. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: (Required) The name of the App Service Certificate Order resource. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: (Required) The resource group where the resources will be deployed. Changing this forces a new resource to be created.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_auto_renew"></a> [auto\_renew](#input\_auto\_renew)

Description: (Optional) true if the certificate should be automatically renewed when it expires; otherwise, false. Defaults to `true`.

Type: `bool`

Default: `true`

### <a name="input_certificate_order_key_vault_store"></a> [certificate\_order\_key\_vault\_store](#input\_certificate\_order\_key\_vault\_store)

Description: A map of App Servicce Certificate Order Key Vault Stores to create on App Service Certificate Order.

- `name` - Specifies the name of the Certificate Key Vault Store. Changing this forces a new resource to be created.
- `key_vault_id` - The ID of the Key Vault in which to bind the Certificate.
- `key_vault_secret_name` - The name of the Key Vault Secret to bind to the Certificate.
- `tags` - A mapping of tags which should be assigned to the App Servicce Certificate Order Key Vault Store.

Type:

```hcl
object({
    name                  = string
    key_vault_id          = string
    key_vault_secret_name = string
    tags                  = optional(map(string), null)
  })
```

Default: `null`

### <a name="input_csr"></a> [csr](#input\_csr)

Description: (Optional) Last CSR that was created for this order.

Type: `string`

Default: `null`

### <a name="input_distinguished_name"></a> [distinguished\_name](#input\_distinguished\_name)

Description: (Optional) The Distinguished Name for the App Service Certificate Order.

Type: `string`

Default: `null`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_key_size"></a> [key\_size](#input\_key\_size)

Description: (Optional) Certificate key size. Defaults to `2048`.

Type: `number`

Default: `2048`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_product_type"></a> [product\_type](#input\_product\_type)

Description: (Optional) Certificate product type, such as `Standard` or `WildCard`. Defaults to `Standard`.

Type: `string`

Default: `"Standard"`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - The type of the principal\_id. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) A mapping of tags which should be assigned to the App Service Certificate Order.

Type: `map(string)`

Default: `null`

### <a name="input_validity_in_years"></a> [validity\_in\_years](#input\_validity\_in\_years)

Description: (Optional) Duration in years (must be between `1` and `3`). Defaults to `1`.

Type: `number`

Default: `1`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The resource of app service certificate order

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource ID of app service certificate order

### <a name="output_resource_in_azurerm_schema"></a> [resource\_in\_azurerm\_schema](#output\_resource\_in\_azurerm\_schema)

Description: The resource of app service certificate order in azurerm schema

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->