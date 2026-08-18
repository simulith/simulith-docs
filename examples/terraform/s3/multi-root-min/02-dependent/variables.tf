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

variable "environment" {
  type    = string
  default = "dev"
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

variable "network_state_key" {
  description = "Object key for the 01-network root state."
  type        = string
  default     = "demo-network-state"
}
