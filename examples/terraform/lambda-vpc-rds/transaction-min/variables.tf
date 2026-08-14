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

variable "user_database" {
  type    = string
  default = "demoapp"
}

variable "password_database" {
  type      = string
  default   = "local-dev-password"
  sensitive = true
}

variable "lambda_role_arn" {
  type    = string
  default = "arn:aws:iam::000000000000:role/demoapp-dev-lambda"
}
