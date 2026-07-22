# Secrets Manager secret + version — green path on Simulith.
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

resource "aws_secretsmanager_secret" "app" {
  name                    = var.secret_name
  description             = "Simulith Terraform green path"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    username   = "admin"
    password   = "local-dev"
    managed_by = "terraform"
  })
}
