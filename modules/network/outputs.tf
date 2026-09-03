output "vpc_id" {
  description = "ID of the project VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "ID of the public subnet."
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "IPv4 CIDR range assigned to the public subnet."
  value       = aws_subnet.public.cidr_block
}

output "availability_zone" {
  description = "Availability Zone containing the public subnet."
  value       = aws_subnet.public.availability_zone
}