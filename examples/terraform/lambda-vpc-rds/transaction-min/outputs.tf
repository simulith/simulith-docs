output "lambda_function_name" {
  value = aws_lambda_function.transaction_probe.function_name
}

output "rds_proxy_endpoint" {
  value = module.postgres_min.rds_proxy_endpoint
}

output "vpc_config_subnet_ids" {
  value = aws_lambda_function.transaction_probe.vpc_config[0].subnet_ids
}
