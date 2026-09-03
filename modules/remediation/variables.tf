variable "name_prefix" {
  description = "Prefix used when naming remediation resources."
  type        = string
}

variable "security_group_id" {
  description = "Only security group the remediation function may modify."
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.security_group_id))
    error_message = "security_group_id must be a valid AWS security group ID."
  }
}