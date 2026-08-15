output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.vpc.id
}

output "secret_arn" {
  description = "Secrets Manager ARN for database credentials"
  value       = aws_secretsmanager_secret.db.arn
}

output "kms_key_arn" {
  description = "KMS CMK ARN used for the database secret"
  value       = aws_kms_key.app_cmk.arn
}

output "postgres_db_endpoint" {
  description = "Direct RDS instance endpoint (127.0.0.1 on Simulith)"
  value       = aws_db_instance.app_db.endpoint
}

output "postgres_db_port" {
  description = "Mapped host port for direct psql"
  value       = aws_db_instance.app_db.port
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint (host:port on Simulith)"
  value       = aws_db_proxy.proxy.endpoint
}

output "rds_proxy_arn" {
  description = "RDS Proxy ARN"
  value       = aws_db_proxy.proxy.arn
}

output "proxy_subnet_ids" {
  description = "Subnet IDs for Lambda VpcConfig (proxy subnets 4–5)"
  value       = [aws_subnet.proxy_subnet_1.id, aws_subnet.proxy_subnet_2.id]
}

output "proxy_security_group_id" {
  description = "Security group ID for Lambda VpcConfig (proxy SG)"
  value       = aws_security_group.proxy_security_group.id
}
