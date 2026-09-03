variable "name_prefix" {
  description = "Prefix used when naming EC2 resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC containing the EC2 instance."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range of the VPC."
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet containing the EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used by the security lab."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.instance_type)
    error_message = "instance_type must be t2.micro or t3.micro for this lab."
  }
}

variable "data_bucket_arn" {
  description = "ARN of the S3 bucket accessible to the EC2 workload."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:s3:::[a-z0-9.-]+$", var.data_bucket_arn))
    error_message = "data_bucket_arn must be a valid S3 bucket ARN."
  }
}