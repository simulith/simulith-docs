# Loyaleasy-min: VPC + RDS Proxy + Lambda VpcConfig (SML-195 / FW-VPC-010).
# Subset of transaction-api pattern: Lambda in proxy subnets reaches RDS_PROXY_ENDPOINT.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "database_subnet_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "database_subnet_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "proxy_subnet_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
}

resource "aws_subnet" "proxy_subnet_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.5.0/24"
}

resource "aws_security_group" "database_sg" {
  name   = "${local.name_prefix}-database-sg"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "proxy_sg" {
  name   = "${local.name_prefix}-proxy-sg"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_db_subnet_group" "subnet" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.database_subnet_1.id, aws_subnet.database_subnet_2.id]
}

resource "aws_db_instance" "db" {
  identifier        = local.name_prefix
  engine            = "postgres"
  engine_version    = "15.13"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = var.user_database
  password          = var.password_database
  db_subnet_group_name   = aws_db_subnet_group.subnet.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  skip_final_snapshot    = true
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "proxy" {
  name               = "${local.name_prefix}-rds-proxy-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_db_proxy" "proxy" {
  name                   = "${local.name_prefix}-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.proxy.arn
  vpc_subnet_ids         = [aws_subnet.proxy_subnet_1.id, aws_subnet.proxy_subnet_2.id]
  vpc_security_group_ids = [aws_security_group.proxy_sg.id]
  require_tls            = true

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = var.secret_arn
    iam_auth    = "DISABLED"
  }
}

resource "aws_db_proxy_default_target_group" "default" {
  db_proxy_name = aws_db_proxy.proxy.name
}

resource "aws_db_proxy_target" "db" {
  db_proxy_name          = aws_db_proxy.proxy.name
  target_group_name      = aws_db_proxy_default_target_group.default.name
  db_instance_identifier = aws_db_instance.db.identifier
}

data "archive_file" "probe" {
  type        = "zip"
  source_file = "${path.module}/handler.js"
  output_path = "${path.module}/.build/probe.zip"
}

resource "aws_lambda_function" "transaction_probe" {
  function_name = "${local.name_prefix}-transaction-probe"
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  filename         = data.archive_file.probe.output_path
  source_code_hash = data.archive_file.probe.output_base64sha256

  vpc_config {
    subnet_ids         = [aws_subnet.proxy_subnet_1.id, aws_subnet.proxy_subnet_2.id]
    security_group_ids = [aws_security_group.proxy_sg.id]
  }

  environment {
    variables = {
      RDS_PROXY_ENDPOINT = aws_db_proxy.proxy.endpoint
    }
  }
}
