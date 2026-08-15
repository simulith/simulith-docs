# Child root used only to prove terraform init against the state bucket.

terraform {
  backend "s3" {
    bucket         = "demo-terraform-state"
    key            = "demo-vpc-state"
    region         = "us-east-1"
    dynamodb_table = "demo_terraform_lock"
    encrypt        = true
  }
}

output "backend_ready" {
  value = true
}
