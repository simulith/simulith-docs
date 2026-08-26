output "user_pool_id" {
  description = "User pool ID (parameters/ remote state)."
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.main.arn
}

output "client_id" {
  description = "App client ID (parameters/ remote state)."
  value       = aws_cognito_user_pool_client.app.id
}

output "domain" {
  value = aws_cognito_user_pool_domain.main.domain
}

output "jwks_url" {
  value = "${var.simulith_endpoint}/${aws_cognito_user_pool.main.id}/.well-known/jwks.json"
}
