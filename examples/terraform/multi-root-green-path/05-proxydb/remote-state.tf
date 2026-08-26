# Production-shaped remote state: no endpoints, skip_*, or use_path_style in .tf.
# Env: AWS_ENDPOINT_URL / AWS_ENDPOINT_URL_S3 / AWS_ENDPOINT_URL_DYNAMODB + creds.
# Use a hostname that wildcard-resolves to loopback (localhost, or 127.0.0.1.sslip.io on Windows).

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket         = var.state_bucket
    key            = var.vpc_state_key
    region         = var.aws_region
    dynamodb_table = var.lock_table_name
    encrypt        = true
  }
}

data "terraform_remote_state" "subnets" {
  backend = "s3"

  config = {
    bucket         = var.state_bucket
    key            = var.subnets_state_key
    region         = var.aws_region
    dynamodb_table = var.lock_table_name
    encrypt        = true
  }
}

data "terraform_remote_state" "secrets" {
  backend = "s3"

  config = {
    bucket         = var.state_bucket
    key            = var.secrets_state_key
    region         = var.aws_region
    dynamodb_table = var.lock_table_name
    encrypt        = true
  }
}
