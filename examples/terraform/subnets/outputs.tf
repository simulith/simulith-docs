output "vpc_id" {
  description = "VPC ID (postgresdb/ / proxydb/ remote state)."
  value       = aws_vpc.main.id
}

output "database_subnet_1_id" {
  description = "Database subnet 1 (RDS subnet group)."
  value       = aws_subnet.database_subnet_1.id
}

output "database_subnet_2_id" {
  description = "Database subnet 2 (RDS subnet group)."
  value       = aws_subnet.database_subnet_2.id
}

output "database_subnet_3_id" {
  description = "Database subnet 3 (RDS subnet group)."
  value       = aws_subnet.database_subnet_3.id
}

output "database_subnet_4_id" {
  description = "Database subnet 4 (RDS Proxy / Lambda VPC)."
  value       = aws_subnet.database_subnet_4.id
}

output "database_subnet_5_id" {
  description = "Database subnet 5 (RDS Proxy / Lambda VPC)."
  value       = aws_subnet.database_subnet_5.id
}

output "database_subnet_6_id" {
  description = "Database subnet 6 (RDS Proxy / Lambda VPC)."
  value       = aws_subnet.database_subnet_6.id
}

output "public_route_table_id" {
  description = "Public route table ID."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private route table ID."
  value       = aws_route_table.private.id
}
