output "postgres_db_sg_id" {
  description = "Database security group ID (proxydb/ remote state)."
  value       = aws_security_group.database_security_group.id
}

output "postgres_db_endpoint" {
  description = "PostgreSQL endpoint (proxydb/ remote state)."
  value       = aws_db_instance.postgres_db.endpoint
}

output "postgres_db_arn" {
  description = "DB instance ARN (proxydb/ remote state)."
  value       = aws_db_instance.postgres_db.arn
}

output "postgres_db_id" {
  description = "DB instance identifier (proxydb/ remote state)."
  value       = aws_db_instance.postgres_db.id
}
