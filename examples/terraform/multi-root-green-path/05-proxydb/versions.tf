terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "demo-terraform-state"
    key            = "demo-proxydb-state"
    region         = "us-east-1"
    dynamodb_table = "demo_terraform_lock"
    encrypt        = true
  }
}
