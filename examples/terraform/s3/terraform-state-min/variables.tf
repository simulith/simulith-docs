variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint when use_simulith_endpoint is true."
  type        = string
  default     = "http://127.0.0.1:9080/runtime"
}

variable "use_simulith_endpoint" {
  type    = bool
  default = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket for Terraform remote state."
  type        = string
  default     = "demo-terraform-state"
}

variable "lock_table_name" {
  description = "DynamoDB lock table for Terraform state."
  type        = string
  default     = "demo_terraform_lock"
}
