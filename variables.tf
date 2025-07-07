variable "location" {
  type        = string
  description = "(Required) Azure region where the resource should be deployed. Changing this forces a new resource to be created."
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) The name of the App Service Certificate Order resource. Changing this forces a new resource to be created."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The resource group where the resources will be deployed. Changing this forces a new resource to be created."
  nullable    = false
}

variable "auto_renew" {
  type        = bool
  default     = true
  description = "(Optional) true if the certificate should be automatically renewed when it expires; otherwise, false. Defaults to `true`."
}

variable "certificate_order_key_vault_store" {
  type = object({
    name                  = string
    key_vault_id          = string
    key_vault_secret_name = string
    tags                  = optional(map(string), null)
  })
  default     = null
  description = <<DESCRIPTION
A map of App Servicce Certificate Order Key Vault Stores to create on App Service Certificate Order.

- `name` - Specifies the name of the Certificate Key Vault Store. Changing this forces a new resource to be created.
- `key_vault_id` - The ID of the Key Vault in which to bind the Certificate.
- `key_vault_secret_name` - The name of the Key Vault Secret to bind to the Certificate.
- `tags` - A mapping of tags which should be assigned to the App Servicce Certificate Order Key Vault Store.

DESCRIPTION
}

variable "csr" {
  type        = string
  default     = null
  description = "(Optional) Last CSR that was created for this order."
}

variable "distinguished_name" {
  type        = string
  default     = null
  description = "(Optional) The Distinguished Name for the App Service Certificate Order."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "key_size" {
  type        = number
  default     = 2048
  description = "(Optional) Certificate key size. Defaults to `2048`."

  validation {
    condition     = var.key_size >= 0
    error_message = "`key_size` must be greater than or equal to 0."
  }
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "product_type" {
  type        = string
  default     = "Standard"
  description = "(Optional) Certificate product type, such as `Standard` or `WildCard`. Defaults to `Standard`."

  validation {
    condition     = contains(["Standard", "WildCard"], var.product_type)
    error_message = "`product_type` must be one of: `Standard`, `WildCard`."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - The type of the principal_id. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags which should be assigned to the App Service Certificate Order."
}

variable "validity_in_years" {
  type        = number
  default     = 1
  description = "(Optional) Duration in years (must be between `1` and `3`). Defaults to `1`."

  validation {
    condition     = var.validity_in_years >= 1 && var.validity_in_years <= 3
    error_message = "`validity_in_years` must be between 1 and 3 inclusive."
  }
}
