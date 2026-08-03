output "postgres_db_sg_id" {
  description = "Database security group ID"
  value       = aws_security_group.database_security_group.id
}

output "postgres_db_endpoint" {
  description = "PostgreSQL endpoint hostname (127.0.0.1 on Simulith)"
  value       = aws_db_instance.loyaleasy_db.endpoint
}

output "postgres_db_port" {
  description = "Mapped host port for local psql"
  value       = aws_db_instance.loyaleasy_db.port
}

output "postgres_db_arn" {
  description = "DB instance ARN"
  value       = aws_db_instance.loyaleasy_db.arn
}

output "postgres_db_id" {
  description = "DB instance identifier"
  value       = aws_db_instance.loyaleasy_db.id
}
