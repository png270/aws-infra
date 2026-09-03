output "trail_name" {
  description = "Name of the project CloudTrail trail."
  value       = aws_cloudtrail.this.name
}

output "trail_arn" {
  description = "ARN of the project CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

output "audit_bucket_id" {
  description = "Name of the CloudTrail audit bucket."
  value       = aws_s3_bucket.audit.id
}

output "audit_bucket_arn" {
  description = "ARN of the CloudTrail audit bucket."
  value       = aws_s3_bucket.audit.arn
}