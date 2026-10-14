mock_provider "azapi" {
  alias = "mock"

  mock_data "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
    }
  }

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.CertificateRegistration/certificateOrders/test-cert"
    }
  }
}

mock_provider "modtm" {
  alias = "mock"
}

mock_provider "random" {
  alias = "mock"
}

variables {
  location            = "global"
  name                = "test-cert"
  resource_group_name = "test-rg"
  distinguished_name  = "CN=example.com"
  enable_telemetry    = false
}

run "default_compatibility_output" {
  command = apply

  providers = {
    azapi  = azapi.mock
    modtm  = modtm.mock
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
    modtm  = modtm.mock
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
    modtm  = modtm.mock
    random = random.mock
  }

  variables {
    csr = "test-csr"
  }

  expect_failures = [azapi_resource.app_service_certificate_order]
}
