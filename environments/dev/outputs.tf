output "vpc_id" {
  description = "ID of the project VPC."
  value       = module.network.vpc_id
}

output "public_subnet_id" {
  description = "ID of the project public subnet."
  value       = module.network.public_subnet_id
}

output "public_subnet_cidr" {
  description = "CIDR range of the project public subnet."
  value       = module.network.public_subnet_cidr
}

output "availability_zone" {
  description = "Availability Zone selected for the project."
  value       = module.network.availability_zone
}

#The module outputs values to the root module, and the root module decides which of those should be visible to the operator.

output "instance_id" {
  description = "ID of the hardened EC2 instance."
  value       = module.ec2.instance_id
}

output "instance_security_group_id" {
  description = "ID of the hardened instance security group."
  value       = module.ec2.security_group_id
}

output "instance_role_name" {
  description = "Name of the EC2 IAM role."
  value       = module.ec2.iam_role_name
}

output "instance_public_ip" {
  description = "Temporary public IPv4 address of the lab instance."
  value       = module.ec2.public_ip
}

output "data_bucket_name" {
  description = "Name of the hardened S3 data bucket."
  value       = module.s3.bucket_id
}

output "data_bucket_arn" {
  description = "ARN of the hardened S3 data bucket."
  value       = module.s3.bucket_arn
}

output "cloudtrail_name" {
  description = "Name of the project CloudTrail trail."
  value       = module.audit.trail_name
}

output "audit_bucket_name" {
  description = "Name of the CloudTrail audit bucket."
  value       = module.audit.audit_bucket_id
}

output "remediation_function_name" {
  description = "Name of the security-group remediation function."
  value       = module.remediation.function_name
}

output "remediation_event_rule_name" {
  description = "Name of the public-ingress detection rule."
  value       = module.remediation.event_rule_name
}

output "remediation_log_group_name" {
  description = "Log group containing remediation evidence."
  value       = module.remediation.log_group_name
}