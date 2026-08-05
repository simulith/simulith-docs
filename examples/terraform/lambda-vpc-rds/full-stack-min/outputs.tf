output "lambda_function_name" {
  value = aws_lambda_function.transaction_probe.function_name
}

output "rds_proxy_endpoint" {
  value = aws_db_proxy.proxy.endpoint
}

output "vpc_config_subnet_ids" {
  value = aws_lambda_function.transaction_probe.vpc_config[0].subnet_ids
}
