output "kms_key_arn" {
  value = aws_kms_key.app_cmk.arn
}

output "kms_key_id" {
  value = aws_kms_key.app_cmk.key_id
}

output "kms_alias_name" {
  value = aws_kms_alias.app_cmk.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}
