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

variable "function_name" {
  type    = string
  default = "eb-schedule-demo"
}

variable "rule_name" {
  type    = string
  default = "eb-schedule-demo"
}

variable "lambda_role_arn" {
  type    = string
  default = "arn:aws:iam::000000000000:role/simulith-lambda-tf"
}
