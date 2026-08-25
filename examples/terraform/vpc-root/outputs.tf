output "vpc_id" {
  description = "VPC ID (subnets/ remote state)."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.main.cidr_block
}

output "public_route_table_id" {
  description = "Public route table ID (subnets/ associations)."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private route table ID (subnets/ associations)."
  value       = aws_route_table.private.id
}
