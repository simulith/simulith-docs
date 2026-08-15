# VPC + RDS + Proxy module + Lambda VpcConfig probe (no remote state).

module "vpc_rds_proxy" {
  source = "../../rds/vpc-rds-proxy-min"

  aws_region            = var.aws_region
  use_simulith_endpoint = var.use_simulith_endpoint
  simulith_endpoint     = var.simulith_endpoint
  project_name          = var.project_name
  environment           = var.environment
  user_database         = var.user_database
  password_database     = var.password_database
}

data "archive_file" "probe" {
  type        = "zip"
  source_file = "${path.module}/handler.js"
  output_path = "${path.module}/.build/probe.zip"
}

resource "aws_lambda_function" "transaction_probe" {
  function_name = "${var.project_name}-${var.environment}-transaction-probe"
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  filename         = data.archive_file.probe.output_path
  source_code_hash = data.archive_file.probe.output_base64sha256

  vpc_config {
    subnet_ids         = module.vpc_rds_proxy.proxy_subnet_ids
    security_group_ids = [module.vpc_rds_proxy.proxy_security_group_id]
  }

  environment {
    variables = {
      RDS_PROXY_ENDPOINT = module.vpc_rds_proxy.rds_proxy_endpoint
    }
  }
}
