# KMS CMK + Secrets Manager subset on Simulith.
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_kms_key" "app_cmk" {
  description             = "${var.project_name} ${var.environment} CMK"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "app_cmk" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.app_cmk.key_id
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name_prefix}/database"
  description             = "Database credentials for local stack"
  kms_key_id              = aws_kms_key.app_cmk.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username           = var.db_username
    password           = var.db_password
    database_name      = var.project_name
    port               = 5432
    encryption_key_id  = aws_kms_key.app_cmk.arn
  })
}
