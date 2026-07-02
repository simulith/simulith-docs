terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb = var.simulith_endpoint
  }
}

resource "aws_dynamodb_table" "music" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Artist"

  attribute {
    name = "Artist"
    type = "S"
  }
}
