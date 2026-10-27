mock_provider "azapi" {
  alias = "mock"

  mock_data "azapi_client_config" {
    defaults = {
      object_id                = "00000000-0000-0000-0000-000000000001"
      subscription_id          = "00000000-0000-0000-0000-000000000002"
      tenant_id                = "00000000-0000-0000-0000-000000000003"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000002"
    }
  }

  mock_data "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/certificate-test"
    }
  }

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/certificate-test"
    }
  }
}

mock_provider "azuread" {
  alias = "legacy_name"

  mock_data "azuread_service_principal" {
    defaults = {
      client_id    = "f3c21649-0979-4721-ac85-b0216b2cf413"
      display_name = "Microsoft.Azure.CertificateRegistration"
      object_id    = "00000000-0000-0000-0000-000000000004"
    }
  }
}

mock_provider "azuread" {
  alias = "renamed"

  mock_data "azuread_service_principal" {
    defaults = {
      client_id    = "f3c21649-0979-4721-ac85-b0216b2cf413"
      display_name = "Microsoft certificate reseller CSM Resource Provider"
      object_id    = "00000000-0000-0000-0000-000000000004"
    }
  }
}

mock_provider "random" {
  alias = "mock"

  mock_resource "random_integer" {
    defaults = {
      result = 0
    }
  }

  mock_resource "random_string" {
    defaults = {
      id     = "testx"
      result = "testx"
    }
  }
}

override_data {
  target = data.azuread_service_principal.app_service_spn
  values = {
    client_id = "abfa0a7c-a6b6-4736-8310-5855508787cd"
    object_id = "00000000-0000-0000-0000-000000000005"
  }
}

override_resource {
  target = azapi_resource.key_vault
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/certificate-test/providers/Microsoft.KeyVault/vaults/certificate-test"
  }
}

override_resource {
  target = azapi_resource.dns_zone
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/certificate-test/providers/Microsoft.Network/dnsZones/example.com"
  }
}

override_resource {
  target = module.test.azapi_resource.app_service_certificate_order
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/certificate-test/providers/Microsoft.CertificateRegistration/certificateOrders/certificate-test"
  }
}

override_resource {
  target = module.test.azapi_resource.app_service_certificate_order_key_vault_store["default"]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/certificate-test/providers/Microsoft.CertificateRegistration/certificateOrders/certificate-test/certificates/default"
  }
}

variables {
  location         = "eastus"
  enable_telemetry = false
}

run "legacy_display_name_control" {
  command = apply

  module {
    source = "./examples/default"
  }

  providers = {
    azapi   = azapi.mock
    azuread = azuread.legacy_name

    random = random.mock
  }

  assert {
    condition = (
      data.azuread_service_principal.cert_spn.client_id == "f3c21649-0979-4721-ac85-b0216b2cf413" &&
      data.azuread_service_principal.cert_spn.display_name == "Microsoft.Azure.CertificateRegistration" &&
      data.azuread_service_principal.cert_spn.object_id == "00000000-0000-0000-0000-000000000004"
    )
    error_message = "The canonical application must resolve to the existing tenant object under its legacy display name."
  }

  assert {
    condition = (
      azapi_resource.key_vault.body.properties.accessPolicies[2].objectId == data.azuread_service_principal.cert_spn.object_id &&
      azapi_resource.key_vault.body.properties.accessPolicies[2].objectId != data.azuread_service_principal.cert_spn.client_id
    )
    error_message = "The certificate access policy must use the returned tenant object ID, not the application ID."
  }
}

run "renamed_certificate_principal" {
  command = apply

  module {
    source = "./examples/default"
  }

  providers = {
    azapi   = azapi.mock
    azuread = azuread.renamed

    random = random.mock
  }

  assert {
    condition = (
      data.azuread_service_principal.cert_spn.client_id == "f3c21649-0979-4721-ac85-b0216b2cf413" &&
      data.azuread_service_principal.cert_spn.display_name == "Microsoft certificate reseller CSM Resource Provider" &&
      data.azuread_service_principal.cert_spn.object_id == "00000000-0000-0000-0000-000000000004"
    )
    error_message = "A renamed certificate-registration principal must resolve to the same application and tenant object."
  }

  assert {
    condition = length([
      for display_name in [data.azuread_service_principal.cert_spn.display_name] : display_name
      if display_name == "Microsoft.Azure.CertificateRegistration"
    ]) == 0
    error_message = "The legacy display-name predicate must have no match in the renamed-principal fixture."
  }

  assert {
    condition = jsonencode(azapi_resource.key_vault.body.properties.accessPolicies[2]) == jsonencode({
      objectId = "00000000-0000-0000-0000-000000000004"
      permissions = {
        certificates = ["Create", "Delete", "Get", "Purge", "Import", "List"]
        keys         = []
        secrets      = ["Delete", "Get", "Purge", "Set", "List"]
        storage      = []
      }
      tenantId = "00000000-0000-0000-0000-000000000003"
    })
    error_message = "Renaming the principal must not alter its tenant object ID, tenant ID, or Key Vault permissions."
  }

  assert {
    condition = (
      data.azuread_service_principal.app_service_spn.display_name == "Microsoft Azure App Service" &&
      azapi_resource.key_vault.body.properties.accessPolicies[1].objectId == "00000000-0000-0000-0000-000000000005" &&
      length(azapi_resource.key_vault.body.properties.accessPolicies) == 3
    )
    error_message = "The existing App Service lookup and all three access policy entries must remain intact."
  }
}
