terraform {
  encryption {
    key_provider "pbkdf2" "this" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "this" {
      keys = key_provider.pbkdf2.this
    }

    state {
      method   = method.aes_gcm.this
      enforced = true
    }

    plan {
      method   = method.aes_gcm.this
      enforced = true
    }
  }
}