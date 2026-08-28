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

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "bucket_name" {
  type    = string
  default = "demoapp-dev-web-origin"
}

variable "zone_name" {
  type    = string
  default = "demoapp-dev-web.local"
}

variable "domain_name" {
  type    = string
  default = "cdn.demoapp-dev-web.local"
}
