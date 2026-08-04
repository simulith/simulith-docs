output "kms_key_arn" {
  value = aws_kms_key.loyaleasy.arn
}

output "kms_key_id" {
  value = aws_kms_key.loyaleasy.key_id
}

output "kms_alias_name" {
  value = aws_kms_alias.loyaleasy.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}
