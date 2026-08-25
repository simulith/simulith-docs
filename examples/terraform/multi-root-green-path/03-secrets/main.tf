# Production secrets/ root — reads vpc/ + subnets/ remote state (generic demoapp).

resource "aws_kms_key" "secrets" {
  description             = "KMS key for ${var.project_name} ${local.environment} Secrets Manager"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_secretsmanager_secret" "rds_db" {
  name                    = "${local.name_prefix}-secret"
  description             = "Database credentials for ${var.project_name} ${local.environment}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 0

  tags = {
    Name        = "${local.name_prefix}-secret"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "database-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "rds_db" {
  secret_id = aws_secretsmanager_secret.rds_db.id
  secret_string = jsonencode({
    username          = var.db_username
    password          = var.db_password
    database_name     = var.project_name
    port              = var.db_port
    encryption_key_id = aws_kms_key.secrets.arn
  })
}

resource "aws_security_group" "secrets_manager" {
  name   = "${local.name_prefix}-secrets-manager-sg"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-secrets-manager-sg"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "secrets-manager-endpoint-access"
  }
}

resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [local.subnet_id]
  security_group_ids  = [aws_security_group.secrets_manager.id]
  private_dns_enabled = true

  tags = {
    Name        = "${local.name_prefix}-secrets-manager-endpoint"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "secrets-manager-vpc-endpoint"
  }
}
