# Single-root green path on Simulith.
# One apply: VPC + KMS + Secrets Manager + RDS Postgres + RDS Proxy (no remote state).

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- KMS + Secrets ---

resource "aws_kms_key" "app_cmk" {
  description = "${var.project_name} ${var.environment} CMK"
}

resource "aws_kms_alias" "app_cmk" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.app_cmk.key_id
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name_prefix}/database"
  description             = "Postgres credentials for ${var.project_name}"
  kms_key_id              = aws_kms_key.app_cmk.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username          = var.user_database
    password          = var.password_database
    engine            = "postgres"
    dbname            = var.project_name
    database_name     = var.project_name
    port              = 5432
    encryption_key_id = aws_kms_key.app_cmk.arn
  })
}

# --- VPC + subnets + security groups (vpc/ + subnets/ subset) ---

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.name_prefix}-VPC"
    Environment = var.environment
  }
}

resource "aws_subnet" "database_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.name_prefix}-database-subnet-1"
  }
}

resource "aws_subnet" "database_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${local.name_prefix}-database-subnet-2"
  }
}

resource "aws_subnet" "proxy_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.name_prefix}-proxy-subnet-1"
  }
}

resource "aws_subnet" "proxy_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${local.name_prefix}-proxy-subnet-2"
  }
}

resource "aws_security_group" "database_security_group" {
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for PostgreSQL database"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "PostgreSQL access from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-database-sg"
  }
}

resource "aws_security_group" "proxy_security_group" {
  name        = "${local.name_prefix}-proxy-sg"
  description = "Security group for RDS Proxy"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-proxy-sg"
  }
}

# --- RDS Postgres (postgresdb/ subset) ---

resource "aws_db_subnet_group" "subnet" {
  name        = "${local.name_prefix}-db-subnet-group"
  subnet_ids  = [aws_subnet.database_subnet_1.id, aws_subnet.database_subnet_2.id]
  description = "Subnet group for ${var.project_name} PostgreSQL database"
}

resource "aws_db_parameter_group" "postgres_params" {
  name   = "${local.name_prefix}-postgres-params"
  family = "postgres15"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }
}

resource "aws_db_instance" "app_db" {
  identifier     = local.name_prefix
  engine         = "postgres"
  engine_version = "15.13"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.project_name
  username = var.user_database
  password = var.password_database

  db_subnet_group_name   = aws_db_subnet_group.subnet.name
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  parameter_group_name   = aws_db_parameter_group.postgres_params.name
  publicly_accessible    = false
  port                   = 5432

  skip_final_snapshot = true
}

# --- IAM + RDS Proxy (proxydb/ subset) ---

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

data "aws_iam_policy_document" "rds_proxy_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [aws_secretsmanager_secret.db.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [aws_kms_key.app_cmk.arn]
  }
}

resource "aws_iam_policy" "rds_proxy" {
  name   = "${local.name_prefix}-rds-proxy-policy"
  policy = data.aws_iam_policy_document.rds_proxy_policy.json
}

resource "aws_iam_role" "proxy" {
  name               = "${local.name_prefix}-rds-proxy-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "proxy" {
  role       = aws_iam_role.proxy.name
  policy_arn = aws_iam_policy.rds_proxy.arn
}

resource "aws_db_proxy" "proxy" {
  name                   = "${local.name_prefix}-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.proxy.arn
  vpc_subnet_ids         = [aws_subnet.proxy_subnet_1.id, aws_subnet.proxy_subnet_2.id]
  vpc_security_group_ids = [aws_security_group.proxy_security_group.id]
  require_tls            = true
  debug_logging          = false
  idle_client_timeout    = 1800

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_secretsmanager_secret.db.arn
    iam_auth    = "DISABLED"
  }
}

resource "aws_db_proxy_default_target_group" "default" {
  db_proxy_name = aws_db_proxy.proxy.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "db" {
  db_proxy_name          = aws_db_proxy.proxy.name
  target_group_name      = aws_db_proxy_default_target_group.default.name
  db_instance_identifier = aws_db_instance.app_db.identifier
}
