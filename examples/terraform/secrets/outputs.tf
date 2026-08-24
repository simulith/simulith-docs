output "secret_arn" {
  description = "Secrets Manager secret ARN."
  value       = aws_secretsmanager_secret.rds_db.arn
}

output "secret_name" {
  description = "Secrets Manager secret name (parameters/ remote state)."
  value       = aws_secretsmanager_secret.rds_db.name
}

output "kms_key_id" {
  description = "KMS key ID."
  value       = aws_kms_key.secrets.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN."
  value       = aws_kms_key.secrets.arn
}

output "secrets_manager_sg" {
  description = "Security group for Secrets Manager VPC endpoint (parameters/ remote state)."
  value       = aws_security_group.secrets_manager.id
}

output "secrets_manager_endpoint_id" {
  description = "VPC endpoint ID for Secrets Manager."
  value       = aws_vpc_endpoint.secrets_manager.id
}
