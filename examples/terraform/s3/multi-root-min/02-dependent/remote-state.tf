# Reads 01-network outputs. Endpoints are the Simulith delta:
# terraform init -backend-config does not apply to this data source.

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
    skip_metadata_api_check     = var.use_simulith_endpoint
    use_path_style              = var.use_simulith_endpoint
    access_key                  = var.use_simulith_endpoint ? "test" : null
    secret_key                  = var.use_simulith_endpoint ? "secret" : null
    endpoints = var.use_simulith_endpoint ? {
      s3       = var.simulith_endpoint
      dynamodb = var.simulith_endpoint
    } : null
  }
}
