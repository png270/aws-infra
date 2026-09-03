output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.id
}

output "github_deploy_role_arn" {
  description = "IAM role assumed by GitHub Actions through OIDC."
  value       = aws_iam_role.github_deploy.arn
}

output "github_oidc_subject" {
  description = "Exact GitHub OIDC subject trusted by AWS."
  value       = local.github_subject
}