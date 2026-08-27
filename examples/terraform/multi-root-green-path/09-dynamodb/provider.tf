provider "aws" {
  region = var.aws_region

  access_key                  = var.use_simulith_endpoint ? "test" : null
  secret_key                  = var.use_simulith_endpoint ? "secret" : null
  skip_credentials_validation = var.use_simulith_endpoint
  skip_metadata_api_check     = var.use_simulith_endpoint
  skip_requesting_account_id  = var.use_simulith_endpoint

  dynamic "endpoints" {
    for_each = var.use_simulith_endpoint ? [1] : []
    content {
      dynamodb = var.simulith_endpoint
    }
  }
}
