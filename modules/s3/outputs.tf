output "bucket_id" {
  description = "Name of the hardened data bucket."
  value       = aws_s3_bucket.data.id
}

output "bucket_arn" {
  description = "ARN of the hardened data bucket."
  value       = aws_s3_bucket.data.arn
}

output "bucket_domain_name" {
  description = "Regional domain name of the hardened data bucket."
  value       = aws_s3_bucket.data.bucket_regional_domain_name
}

