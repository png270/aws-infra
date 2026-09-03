variable "name_prefix" {
  description = "Prefix used when naming network resources."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR range assigned to the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}