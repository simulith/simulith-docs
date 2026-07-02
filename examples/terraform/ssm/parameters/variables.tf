################################################################################
# Simulith extension — endpoint routing and local infra mocks
################################################################################

variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint when use_simulith_endpoint is true. All-in-one: http://127.0.0.1:9080/runtime. Native: http://127.0.0.1:4566"
  type        = string
  default     = "http://127.0.0.1:9080/runtime"
}

variable "use_simulith_endpoint" {
  description = "When true, route SSM API calls to Simulith; when false, use real AWS"
  type        = bool
  default     = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "use_remote_state" {
  description = "When true, read infra values from terraform_remote_state (real AWS stacks). When false, use *_override variables (Simulith local)."
  type        = bool
  default     = false
}

variable "remote_state_bucket" {
  type    = string
  default = "loyaleasy-terraform-state"
}

################################################################################
# Required variables (same names as original Loyaleasy module)
################################################################################

variable "env" {
  type        = string
  description = "Environment segment in SSM paths — DEV or PROD (original uses uppercase in /{PROJECT}/{env}/)."

  validation {
    condition     = contains(["DEV", "PROD", "STAGING"], var.env)
    error_message = "env must be DEV, PROD, or STAGING."
  }
}

variable "access_key_id" {
  type        = string
  sensitive   = true
  description = "AWS Access Key ID. Provide via tfvars or TF_VAR_access_key_id."
  default     = "AKIALOCALDEMOKEY"
}

variable "secret_access_key" {
  type        = string
  sensitive   = true
  description = "AWS Secret Access Key. Provide via tfvars or TF_VAR_secret_access_key."
  default     = "local-demo-secret-access-key"
}

variable "secret_password" {
  type        = string
  sensitive   = true
  description = "JWT secret password. Provide via tfvars or TF_VAR_secret_password."
  default     = "local-demo-secret-password"
}

################################################################################
# Optional variables (defaults aligned with original Loyaleasy parameters module)
################################################################################

variable "shared_infrastructure_account_id" {
  type        = string
  description = "The AWS account id for shared_infrastructure account."
  default     = "421800335080"
}

variable "account_id" {
  type    = string
  default = "000000000000"
}

variable "algorithm" {
  type    = string
  default = "HS512"
}

variable "api_key" {
  type    = string
  default = "LOYALTY"
}

variable "domain" {
  type    = string
  default = "dev.localhost"
}

variable "endpoint" {
  type        = string
  description = "Application endpoint stored in SSM (Simulith runtime URL locally; DynamoDB URL in original prod)."
  default     = "http://127.0.0.1:9080/runtime"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "jwt_issuer" {
  type        = string
  description = "JWT issuer claim (iss)."
  default     = "https://loyaleasy.com/auth"
}

variable "jwt_audience" {
  type        = string
  description = "JWT audience claim (aud)."
  default     = "loyaleasy-api"
}

variable "project_name" {
  type        = string
  description = "Platform name — used in SSM path /{PROJECT}/{env}/, remote state keys, and tags."
  default     = "simulith"
}

################################################################################
# Infra overrides when use_remote_state = false (Simulith local green path)
################################################################################

variable "database_secret_override" {
  type    = string
  default = "local/database/credentials"
}

variable "vpc_id_override" {
  type    = string
  default = "vpc-local-demo"
}

variable "database_subnet_ids_override" {
  type    = list(string)
  default = ["subnet-db-1", "subnet-db-2", "subnet-db-3", "subnet-db-4", "subnet-db-5", "subnet-db-6"]
}

variable "secrets_manager_sg_override" {
  type    = string
  default = "sg-secrets-local"
}

variable "rds_proxy_endpoint_override" {
  type    = string
  default = "simulith-proxy.local"
}

variable "rds_proxy_sg_override" {
  type    = string
  default = "sg-proxy-local"
}

variable "cognito_user_pool_id_override" {
  type    = string
  default = "us-east-1_LOCALPOOL"
}

variable "cognito_client_id_override" {
  type    = string
  default = "local-cognito-client-id"
}

variable "ses_from_email_override" {
  type    = string
  default = "noreply@localhost"
}

variable "ses_otp_template_name_override" {
  type    = string
  default = "simulith-otp-local"
}
