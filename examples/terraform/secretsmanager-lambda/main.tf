# Secrets Manager secret → Terraform data source → Lambda environment.
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

resource "aws_secretsmanager_secret" "app" {
  name                    = var.secret_name
  description             = "Simulith secret → Lambda env pattern"
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

data "aws_secretsmanager_secret_version" "app" {
  secret_id  = aws_secretsmanager_secret.app.id
  depends_on = [aws_secretsmanager_secret_version.app]
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/handler.js"
  output_path = "${path.module}/.build/lambda.zip"
}

resource "aws_lambda_function" "worker" {
  function_name = var.function_name
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  timeout       = 3
  memory_size   = 128

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      CONFIG_JSON = data.aws_secretsmanager_secret_version.app.secret_string
    }
  }
}
