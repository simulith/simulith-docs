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

variable "email_identity" {
  type    = string
  default = "otp@example.com"
}

variable "template_name" {
  type    = string
  default = "otp"
}
