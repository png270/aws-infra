variable "aws_region" {
  description = "AWS Region in which project resources will be deployed."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS Region name such as us-east-1."
  }
}

variable "project_name" {
  description = "Short name used to identify project resources."
  type        = string
  default     = "secure-hardening"

  validation {
    condition = (
      length(var.project_name) >= 3 &&
      length(var.project_name) <= 24 &&
      can(regex("^[a-z][a-z0-9-]+$", var.project_name))
    )

    error_message = "project_name must be 3-24 lowercase characters, begin with a letter, and contain only letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "owner" {
  description = "Owner recorded in resource tags."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) >= 2
    error_message = "owner must contain at least two non-whitespace characters."
  }
}


variable "vpc_cidr" {
  description = "IPv4 CIDR range assigned to the project VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}


variable "instance_type" {
  description = "EC2 instance type used by the lab."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.instance_type)
    error_message = "instance_type must be t2.micro or t3.micro."
  }
}

