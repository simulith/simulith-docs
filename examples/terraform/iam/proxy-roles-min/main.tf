# Minimum IAM subset for RDS Proxy — role + policy only.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
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

data "aws_iam_policy_document" "rds_proxy_policy" {
  statement {
    sid    = "AllowProxyToGetDbCredsFromSecretsManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [var.secret_arn]
  }

  statement {
    sid    = "AllowProxyToDecryptDbCredsFromSecretsManager"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [var.kms_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "rds_proxy" {
  name        = "${local.name_prefix}-rds-proxy-policy"
  description = "IAM policy for RDS Proxy to access Secrets Manager"
  policy      = data.aws_iam_policy_document.rds_proxy_policy.json
}

resource "aws_iam_role" "proxy" {
  name               = "${local.name_prefix}-rds-proxy-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "proxy" {
  role       = aws_iam_role.proxy.name
  policy_arn = aws_iam_policy.rds_proxy.arn
}
