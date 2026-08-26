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

variable "pool_name" {
  type    = string
  default = "demoapp-dev-cognito"
}

variable "client_name" {
  type    = string
  default = "demoapp-dev-cognito-client"
}

variable "domain_prefix" {
  type    = string
  default = "demoapp-dev-cognito"
}
