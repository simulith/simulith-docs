# SSM parameters against Simulith (PutParameter / GetParameter / DeleteParameter).
#
#   simulith start
#   cd runtime/examples/terraform/ssm
#   terraform init
#   terraform apply

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ssm = "http://127.0.0.1:4566"
  }
}

resource "aws_ssm_parameter" "service_name" {
  name  = "/app/tf-demo/service-name"
  type  = "String"
  value = "demo-service"

  tags = {
    Environment = "local"
    ManagedBy   = "terraform"
  }
}

resource "aws_ssm_parameter" "log_level" {
  name  = "/app/tf-demo/log-level"
  type  = "String"
  value = "debug"
}

resource "aws_ssm_parameter" "api_token" {
  name  = "/app/tf-demo/api-token"
  type  = "SecureString"
  value = "demo-secret-token"
}
