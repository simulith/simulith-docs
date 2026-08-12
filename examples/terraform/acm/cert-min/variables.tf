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
  default = "demoapp-dev-acm.local"
}

variable "domain_name" {
  type    = string
  default = "demoapp-dev-acm.local"
}

variable "subject_alternative_names" {
  type    = list(string)
  default = ["www.demoapp-dev-acm.local"]
}
