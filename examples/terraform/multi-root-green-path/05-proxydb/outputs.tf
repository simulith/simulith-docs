output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint (parameters/ remote state)."
  value       = aws_db_proxy.proxy.endpoint
}

output "rds_proxy_sg" {
  description = "RDS Proxy security group ID (parameters/ remote state)."
  value       = aws_security_group.sg.id
}

output "rds_proxy_arn" {
  description = "RDS Proxy ARN."
  value       = aws_db_proxy.proxy.arn
}
