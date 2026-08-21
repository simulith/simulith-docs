# Cognito User Pool + App Client — green path on Simulith.
#
#   terraform apply -var-file=terraform.tfvars -auto-approve
#   terraform destroy -var-file=terraform.tfvars -auto-approve

resource "aws_cognito_user_pool" "main" {
  name = var.pool_name

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length = 8
  }

  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }
}

resource "aws_cognito_user_pool_client" "app" {
  name         = var.client_name
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  generate_secret = false
}

resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Simulith Terraform green path"
}
