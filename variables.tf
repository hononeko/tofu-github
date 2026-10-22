variable "tofu_encryption_passphrase" {
  type        = string
  description = "Passphrase for OpenTofu state and plan client-side encryption"
  sensitive   = true
}
