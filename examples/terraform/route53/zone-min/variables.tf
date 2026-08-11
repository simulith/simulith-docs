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
  default = "demoapp"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "zone_name" {
  type    = string
  default = "demoapp-dev.local"
}

variable "www_ipv4" {
  type    = string
  default = "203.0.113.10"
}

variable "cdn_target" {
  type    = string
  default = "d111111abcdef8.cloudfront.net"
}
