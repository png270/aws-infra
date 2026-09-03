output "instance_id" {
  description = "ID of the hardened EC2 instance."
  value       = aws_instance.this.id
}

output "security_group_id" {
  description = "ID of the EC2 security group."
  value       = aws_security_group.instance.id
}

output "iam_role_name" {
  description = "Name of the EC2 instance IAM role."
  value       = aws_iam_role.instance.name
}

output "public_ip" {
  description = "Temporary public IPv4 address used for outbound connectivity."
  value       = aws_instance.this.public_ip
}

output "ami_id" {
  description = "Amazon Linux 2023 AMI selected for the instance."
  value       = data.aws_ami.amazon_linux.id
}