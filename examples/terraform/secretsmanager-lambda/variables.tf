variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint when use_simulith_endpoint is true. All-in-one: http://127.0.0.1:9080/runtime. Native: http://127.0.0.1:4566"
  type        = string
  default     = "http://127.0.0.1:9080/runtime"
}

variable "use_simulith_endpoint" {
  description = "When true, route Secrets Manager and Lambda API calls to Simulith; when false, use real AWS"
  type        = bool
  default     = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "secret_name" {
  description = "Secrets Manager secret name"
  type        = string
  default     = "app-config-lambda-tf"
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "secret-env-worker-tf"
}

variable "lambda_role_arn" {
  description = "Lambda execution role ARN. Simulith accepts any ARN; real AWS needs a valid role"
  type        = string
  default     = "arn:aws:iam::000000000000:role/simulith-secret-lambda-tf"
}
