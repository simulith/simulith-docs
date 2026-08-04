variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "simulith_endpoint" {
  type    = string
  default = "http://127.0.0.1:4566"
}

variable "use_simulith_endpoint" {
  type    = bool
  default = true
}

variable "project_name" {
  type    = string
  default = "loyaleasy"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "db_username" {
  type    = string
  default = "loyaleasy"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "local-dev-password"
}
