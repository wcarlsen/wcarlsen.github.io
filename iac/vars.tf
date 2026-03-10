variable "state_encryption_passphrase" {
  type        = string
  description = "passphrase used to encrypt the state file"
  validation {
    condition     = length(var.state_encryption_passphrase) >= 16
    error_message = "The passphrase must be at least 16 characters long."
  }
  sensitive = true
}

variable "github_token" {
  type        = string
  description = "Github fine grained token used for Renovate action see https://docs.renovatebot.com/modules/platform/github/#running-using-a-fine-grained-token"
  sensitive   = true
}
