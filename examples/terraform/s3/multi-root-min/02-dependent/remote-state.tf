# Production-shaped remote state: no endpoints in .tf.
# Env: AWS_ENDPOINT_URL / AWS_ENDPOINT_URL_S3 / AWS_ENDPOINT_URL_DYNAMODB + creds.
# Leftover overlay (no HashiCorp env): skip STS checks + path-style (IP endpoint).

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket                      = var.state_bucket
    key                         = var.network_state_key
    region                      = var.aws_region
    dynamodb_table              = var.lock_table_name
    encrypt                     = true
    skip_credentials_validation = var.use_simulith_endpoint
    skip_requesting_account_id  = var.use_simulith_endpoint
    use_path_style              = var.use_simulith_endpoint
  }
}
