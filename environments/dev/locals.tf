locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
    Repository  = "aws-secure-hardening-pipeline"
    Purpose     = "DevSecOps security portfolio project"
  }
}