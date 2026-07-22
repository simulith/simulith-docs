output "secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.app.name
}

output "secret_version_id" {
  value = aws_secretsmanager_secret_version.app.version_id
}
