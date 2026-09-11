# Simulith override for Terraform backend "s3" (remote state + DynamoDB lock).
# Provider endpoints come from AWS profile or provider block — this file is backend-only.
#
# In-repo:  terraform init -backend-config=backend.simulith.hcl -reconfigure
# External: copy this file to your checkout (e.g. infrastructure/backend.simulith.hcl)
#            and init with -backend-config=../backend.simulith.hcl from each module.
# Docs: runtime/docs/terraform-integration.md#s3-remote-state-backend-backendsimulithhcl

endpoints = {
  s3       = "http://127.0.0.1.sslip.io:4566"
  dynamodb = "http://127.0.0.1.sslip.io:4566"
}
skip_credentials_validation = true
skip_requesting_account_id  = true
skip_metadata_api_check     = true
use_path_style              = true
access_key                  = "test"
secret_key                  = "secret"
