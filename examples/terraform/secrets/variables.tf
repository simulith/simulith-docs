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

variable "db_username" {
  type    = string
  default = "demoapp"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "local-dev-password"
}

variable "db_port" {
  type    = number
  default = 5432
}
