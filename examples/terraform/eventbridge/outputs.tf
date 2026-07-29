output "rule_name" {
  value = aws_cloudwatch_event_rule.schedule.name
}

output "rule_arn" {
  value = aws_cloudwatch_event_rule.schedule.arn
}

output "function_name" {
  value = aws_lambda_function.demo.function_name
}

output "function_arn" {
  value = aws_lambda_function.demo.arn
}
