variable "state_encryption_passphrase" {
  type        = string
  description = "passphrase used to encrypt the state file"
  validation {
    condition     = length(var.state_encryption_passphrase) >= 16
    error_message = "The passphrase must be at least 16 characters long."
  }
  sensitive = true
}