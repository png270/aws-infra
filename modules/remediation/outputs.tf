output "function_name" {
  description = "Name of the security-group remediation Lambda."
  value       = aws_lambda_function.remediation.function_name
}

output "event_rule_name" {
  description = "Name of the public-ingress detection rule."
  value       = aws_cloudwatch_event_rule.public_ingress.name
}

output "log_group_name" {
  description = "CloudWatch log group containing remediation evidence."
  value       = aws_cloudwatch_log_group.remediation.name
}