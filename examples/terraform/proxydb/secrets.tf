resource "aws_kms_key" "secrets" {
  description             = "KMS key for ${var.project_name} ${local.environment} Secrets Manager"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_secretsmanager_secret" "rds_db" {
  name                    = "${local.name_prefix}-secret"
  description             = "Database credentials for ${var.project_name} ${local.environment}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_db" {
  secret_id = aws_secretsmanager_secret.rds_db.id
  secret_string = jsonencode({
    username          = var.user_database
    password          = var.password_database
    database_name     = var.project_name
    port              = 5432
    encryption_key_id = aws_kms_key.secrets.arn
  })
}
