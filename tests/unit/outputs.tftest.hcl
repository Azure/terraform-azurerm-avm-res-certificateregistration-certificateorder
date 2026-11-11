mock_provider "azapi" {
  alias = "mock"

  mock_data "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            role_name = "Reader"
          }
        ]
      }
    }
  }

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.CertificateRegistration/certificateOrders/test-cert"
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      object_id                = "00000000-0000-0000-0000-000000000001"
      subscription_id          = "00000000-0000-0000-0000-000000000002"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000002"
      tenant_id                = "00000000-0000-0000-0000-000000000003"
    }
  }
}

mock_provider "random" {
  alias = "mock"

  mock_resource "random_uuid" {
    defaults = {
      result = "00000000-0000-4000-8000-000000000099"
    }
  }
}

variables {
  location            = "eastus"
  name                = "test-cert"
  resource_group_name = "test-rg"
  distinguished_name  = "CN=example.com"
  enable_telemetry    = false
}

run "default_compatibility_output" {
  command = apply

  providers = {
    azapi  = azapi.mock
    random = random.mock
  }

  assert {
    condition = jsonencode(output.resource_in_azurerm_schema) == jsonencode({
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.CertificateRegistration/certificateOrders/test-cert"
      name                = "test-cert"
      resource_group_name = "test-rg"
      auto_renew          = true
      csr                 = null
      distinguished_name  = "CN=example.com"
      key_size            = 2048
      product_type        = "StandardDomainValidatedSsl"
      validity_in_years   = 1
      tags                = {}
    })
    error_message = "The compatibility output must retain every historical field and default value."
  }
}

run "custom_csr_compatibility_output" {
  command = apply

  providers = {
    azapi  = azapi.mock
    random = random.mock
  }

  variables {
    auto_renew         = false
    csr                = "test-csr"
    distinguished_name = null
    key_size           = 4096
    product_type       = "WildCard"
    tags = {
      environment = "test"
    }
    validity_in_years = 3
  }

  assert {
    condition = jsonencode(output.resource_in_azurerm_schema) == jsonencode({
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.CertificateRegistration/certificateOrders/test-cert"
      name                = "test-cert"
      resource_group_name = "test-rg"
      auto_renew          = false
      csr                 = "test-csr"
      distinguished_name  = null
      key_size            = 4096
      product_type        = "StandardDomainValidatedWildCardSsl"
      validity_in_years   = 3
      tags = {
        environment = "test"
      }
    })
    error_message = "The compatibility output must retain custom values and null optional fields."
  }
}

run "reject_conflicting_certificate_inputs" {
  command = plan

  providers = {
    azapi  = azapi.mock
    random = random.mock
  }

  variables {
    csr = "test-csr"
  }

  expect_failures = [azapi_resource.app_service_certificate_order]
}

run "regional_telemetry_keeps_certificate_global" {
  command = apply

  providers = {
    azapi  = azapi.mock
    random = random.mock
  }

  variables {
    enable_telemetry = true
  }

  assert {
    condition = (
      azapi_resource.app_service_certificate_order.location == "global" &&
      azapi_resource.telemetry[0].location == "eastus"
    )
    error_message = "The certificate order must remain global while telemetry uses the configured Azure region."
  }
}

run "telemetry_can_be_disabled" {
  command = apply

  providers = {
    azapi  = azapi.mock
    random = random.mock
  }

  variables {
    enable_telemetry = false
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0
    error_message = "Disabling telemetry must create no telemetry deployment."
  }
}

run "rejects_global_telemetry_location" {
  command = plan

  providers = {
    azapi  = azapi.mock
    random = random.mock
  }

  variables {
    location = "global"
  }

  expect_failures = [var.location]
}

run "preserves_role_assignment_identity_and_payload" {
  command = apply

  providers = {
    azapi  = azapi.mock
    random = random.mock
  }

  variables {
    role_assignments = {
      reader = {
        principal_id               = "00000000-0000-0000-0000-000000000004"
        role_definition_id_or_name = "Reader"
        principal_type             = "User"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["reader"].name == "a457c040-d334-5737-8d23-3cf8e8f1c0d9"
    error_message = "Named role assignments must retain the legacy deterministic UUID."
  }

  assert {
    condition = jsonencode(azapi_resource.role_assignments["reader"].body) == jsonencode({
      properties = {
        principalId                        = "00000000-0000-0000-0000-000000000004"
        roleDefinitionId                   = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        conditionVersion                   = null
        condition                          = null
        description                        = null
        principalType                      = "User"
        delegatedManagedIdentityResourceId = null
      }
    })
    error_message = "The role assignment payload must remain identical to the legacy utility output."
  }
}

run "preserves_legacy_lock_payload" {
  command = apply

  providers = {
    azapi  = azapi.mock
    random = random.mock
  }

  variables {
    lock = {
      kind = "CanNotDelete"
      name = "certificate-order-lock"
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "certificate-order-lock"
    error_message = "The lock name must remain unchanged."
  }

  assert {
    condition = jsonencode(azapi_resource.lock[0].body) == jsonencode({
      properties = {
        level = "CanNotDelete"
      }
    })
    error_message = "The lock payload must preserve the legacy level while excluding only null notes."
  }
}
