variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint when use_simulith_endpoint is true"
  type        = string
  default     = "http://127.0.0.1:4566"
}

variable "use_simulith_endpoint" {
  description = "When true, route Cognito IDP API calls to Simulith"
  type        = bool
  default     = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "pool_name" {
  type    = string
  default = "demoapp-cognito-tf"
}

variable "client_name" {
  type    = string
  default = "demoapp-cognito-client"
}
