# Loyaleasy secrets/ KMS subset on Simulith (SML-196).
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_kms_key" "loyaleasy" {
  description = "loyaleasy ${var.environment} CMK"
}

resource "aws_kms_alias" "loyaleasy" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.loyaleasy.key_id
}

resource "aws_secretsmanager_secret" "db" {
  name        = "${local.name_prefix}/database"
  description = "Database credentials for loyaleasy local stack"
  kms_key_id  = aws_kms_key.loyaleasy.arn
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username           = var.db_username
    password           = var.db_password
    database_name      = var.project_name
    port               = 5432
    encryption_key_id  = aws_kms_key.loyaleasy.arn
  })
}
