variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "use_simulith_endpoint" {
  type    = bool
  default = true
}

variable "simulith_endpoint" {
  type    = string
  default = "http://127.0.0.1:4566"
}

variable "project_name" {
  type    = string
  default = "demoapp"
}

variable "state_bucket" {
  description = "S3 bucket created by terraform-state-min."
  type        = string
  default     = "demo-terraform-state"
}

variable "lock_table_name" {
  type    = string
  default = "demo_terraform_lock"
}

variable "subnets_state_key" {
  description = "Object key for the 02-subnets root state."
  type        = string
  default     = "demo-subnets-state"
}

variable "secrets_state_key" {
  description = "Object key for the 03-secrets root state."
  type        = string
  default     = "demo-secrets-state"
}

variable "proxydb_state_key" {
  description = "Object key for the 05-proxydb root state."
  type        = string
  default     = "demo-proxydb-state"
}

variable "cognito_state_key" {
  description = "Object key for the 07-cognito root state."
  type        = string
  default     = "demo-cognito-state"
}

variable "ses_state_key" {
  description = "Object key for the 06-ses root state."
  type        = string
  default     = "demo-ses-state"
}

variable "env" {
  type        = string
  description = "Environment segment in SSM paths — DEV or PROD (original uses uppercase in /{PROJECT}/{env}/)."

  validation {
    condition     = contains(["DEV", "PROD", "STAGING"], var.env)
    error_message = "env must be DEV, PROD, or STAGING."
  }
}

variable "access_key_id" {
  type      = string
  sensitive = true
  default   = "AKIALOCALDEMOKEY"
}

variable "secret_access_key" {
  type      = string
  sensitive = true
  default   = "local-demo-secret-access-key"
}

variable "secret_password" {
  type      = string
  sensitive = true
  default   = "local-demo-secret-password"
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
  type    = string
  default = "http://127.0.0.1:4566"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "jwt_issuer" {
  type    = string
  default = "https://demoapp.example/auth"
}

variable "jwt_audience" {
  type    = string
  default = "demoapp-api"
}
