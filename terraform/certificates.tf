# ─── Certificate Authority ────────────────────────────────────────────────────

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name         = "${local.prefix} Internal CA"
    organization        = "TestOrg"
    organizational_unit = "Cloud Platform"
  }

  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

# ─── Client Certificate ───────────────────────────────────────────────────────

resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client" {
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name         = "${local.prefix}-client"
    organization        = "TestOrg"
    organizational_unit = "Cloud Platform"
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem   = tls_cert_request.client.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

# ─── Store CA in Key Vault ────────────────────────────────────────────────────

resource "azurerm_key_vault_secret" "ca_cert" {
  name         = "ca-certificate"
  value        = tls_self_signed_cert.ca.cert_pem
  key_vault_id = azurerm_key_vault.this.id
  content_type = "application/x-pem-file"

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "ca_private_key" {
  name         = "ca-private-key"
  value        = tls_private_key.ca.private_key_pem
  key_vault_id = azurerm_key_vault.this.id
  content_type = "application/x-pem-file"

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# ─── Store Client Certificate in Key Vault ───────────────────────────────────

resource "azurerm_key_vault_secret" "client_cert" {
  name         = "client-certificate"
  value        = tls_locally_signed_cert.client.cert_pem
  key_vault_id = azurerm_key_vault.this.id
  content_type = "application/x-pem-file"

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "client_private_key" {
  name         = "client-private-key"
  value        = tls_private_key.client.private_key_pem
  key_vault_id = azurerm_key_vault.this.id
  content_type = "application/x-pem-file"

  depends_on = [azurerm_key_vault_access_policy.terraform]
}
