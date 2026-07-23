output "secret_name" {
  value = aws_secretsmanager_secret.app.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "function_name" {
  value = aws_lambda_function.worker.function_name
}

output "function_arn" {
  value = aws_lambda_function.worker.arn
}
