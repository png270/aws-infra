variable "aws_region" {
  description = "AWS Region used by the deployment."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in bootstrap resources."
  type        = string
  default     = "secure-hardening"
}

variable "github_owner" {
  description = "GitHub repository owner."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name."
  type        = string
}

variable "github_environment" {
  description = "Protected GitHub environment permitted to assume the deployment role."
  type        = string
  default     = "production"
}