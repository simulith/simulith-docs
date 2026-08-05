output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint (host:port on Simulith)"
  value       = aws_db_proxy.proxy.endpoint
}

output "rds_proxy_arn" {
  description = "RDS Proxy ARN"
  value       = aws_db_proxy.proxy.arn
}

output "rds_proxy_sg" {
  description = "RDS Proxy security group ID"
  value       = aws_security_group.proxy_security_group.id
}

output "postgres_db_endpoint" {
  description = "Direct DB instance endpoint"
  value       = aws_db_instance.postgres_db.endpoint
}

output "rds_proxy_role_arn" {
  description = "IAM role ARN for the proxy"
  value       = aws_iam_role.proxy.arn
}
