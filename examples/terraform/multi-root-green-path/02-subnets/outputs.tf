output "vpc_id" {
  description = "VPC ID from vpc/ remote state."
  value       = local.vpc_id
}

output "database_subnet_1_id" {
  value = aws_subnet.database_subnet_1.id
}

output "database_subnet_2_id" {
  value = aws_subnet.database_subnet_2.id
}

output "database_subnet_3_id" {
  value = aws_subnet.database_subnet_3.id
}

output "database_subnet_4_id" {
  value = aws_subnet.database_subnet_4.id
}

output "database_subnet_5_id" {
  value = aws_subnet.database_subnet_5.id
}

output "database_subnet_6_id" {
  value = aws_subnet.database_subnet_6.id
}
