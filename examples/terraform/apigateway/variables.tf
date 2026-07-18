variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint when use_simulith_endpoint is true. All-in-one: http://127.0.0.1:9080/runtime. Native: http://127.0.0.1:4566"
  type        = string
  default     = "http://127.0.0.1:9080/runtime"
}

variable "use_simulith_endpoint" {
  description = "When true, route API Gateway and Lambda API calls to Simulith; when false, use real AWS"
  type        = bool
  default     = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "api_name" {
  description = "API Gateway REST API name"
  type        = string
  default     = "hello-tf"
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

variable "function_name" {
  description = "Lambda function name backing the proxy integration"
  type        = string
  default     = "hello-tf"
}

variable "lambda_role_arn" {
  description = "Lambda execution role ARN. Simulith accepts any ARN; real AWS needs a valid role"
  type        = string
  default     = "arn:aws:iam::000000000000:role/simulith-apigw-tf"
}

variable "resource_path" {
  description = "Path segment under the REST API root (e.g. hello → GET /hello)"
  type        = string
  default     = "hello"
}
