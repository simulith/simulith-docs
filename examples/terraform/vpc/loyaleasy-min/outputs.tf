output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "database_subnet_1_id" {
  value = aws_subnet.database_subnet_1.id
}

output "postgres_security_group_id" {
  value = aws_security_group.postgres.id
}

output "public_route_table_id" {
  value = aws_route_table.public_route_table.id
}

output "private_route_table_id" {
  value = aws_route_table.private_route_table.id
}
