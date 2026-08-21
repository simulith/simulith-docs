output "lambda_role_arn" {
  value = aws_iam_role.lambda.arn
}

output "lambda_inline_policy_name" {
  value = aws_iam_role_policy.lambda_logs.name
}
