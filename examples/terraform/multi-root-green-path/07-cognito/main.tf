# Production cognito/ root — standalone (generic demoapp).

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

  schema {
    name                = "tenant_id"
    attribute_data_type = "String"
    mutable             = true
    required            = false
    string_attribute_constraints {
      min_length = 0
      max_length = 64
    }
  }

  deletion_protection = "INACTIVE"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  lambda_config {
    pre_sign_up       = aws_lambda_function.pre_signup.arn
    post_confirmation = aws_lambda_function.post_confirmation.arn
  }

  tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    Name        = "${local.name_prefix}-cognito"
    Project     = var.project_name
  }
}

resource "aws_cognito_user_pool_client" "app" {
  name         = var.client_name
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]

  generate_secret = false

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  callback_urls = ["http://localhost:5173/callback"]
  logout_urls   = ["http://localhost:5173"]

  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Simulith Terraform green path"
}
