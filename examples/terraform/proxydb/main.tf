# Production proxydb/ root pattern — IAM + RDS Proxy (generic demoapp).

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

data "aws_iam_policy_document" "rds_proxy_policy_document" {
  statement {
    sid = "AllowProxyToGetDbCredsFromSecretsManager"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      aws_secretsmanager_secret.rds_db.arn,
    ]
  }

  statement {
    sid = "AllowProxyToDecryptDbCredsFromSecretsManager"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      aws_kms_key.secrets.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "rds_proxy_iam_policy" {
  name        = "${local.name_prefix}-rds-proxy-policy"
  description = "IAM policy for RDS Proxy to access Secrets Manager"
  policy      = data.aws_iam_policy_document.rds_proxy_policy_document.json
}

resource "aws_iam_role" "role" {
  name               = "${local.name_prefix}-rds-proxy-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "rds_proxy_iam_attach" {
  policy_arn = aws_iam_policy.rds_proxy_iam_policy.arn
  role       = aws_iam_role.role.name
}

resource "aws_security_group" "sg" {
  name        = "${local.name_prefix}-proxy-sg"
  description = "Security group for RDS Proxy - allows PostgreSQL access from VPC only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL access from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-proxy-sg"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "rds-proxy-access"
  }
}

resource "aws_db_proxy" "proxy" {
  name                = "${local.name_prefix}-rds-proxy"
  debug_logging       = false
  engine_family       = "POSTGRESQL"
  idle_client_timeout = local.environment == "prod" ? 1800 : 600
  require_tls         = true
  role_arn            = aws_iam_role.role.arn

  auth {
    description = "RDS Proxy authentication using Secrets Manager"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.rds_db.arn
    auth_scheme = "SECRETS"
  }

  vpc_security_group_ids = [aws_security_group.sg.id]
  vpc_subnet_ids = [
    aws_subnet.database_subnet_4.id,
    aws_subnet.database_subnet_5.id,
    aws_subnet.database_subnet_6.id,
  ]

  tags = {
    Name        = "${local.name_prefix}-rds-proxy"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "rds-connection-pooling"
  }
}

resource "aws_db_proxy_default_target_group" "rds_proxy_target_group" {
  db_proxy_name = aws_db_proxy.proxy.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = local.environment == "prod" ? 100 : 50
    max_idle_connections_percent = local.environment == "prod" ? 50 : 25
  }
}

resource "aws_db_proxy_target" "rds_proxy_target" {
  db_instance_identifier = local.name_prefix
  db_proxy_name          = aws_db_proxy.proxy.name
  target_group_name      = aws_db_proxy_default_target_group.rds_proxy_target_group.name
}
