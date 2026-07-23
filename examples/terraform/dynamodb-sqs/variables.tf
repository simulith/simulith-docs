variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint when use_simulith_endpoint is true. All-in-one: http://127.0.0.1:9080/runtime. Native: http://127.0.0.1:4566"
  type        = string
  default     = "http://127.0.0.1:9080/runtime"
}

variable "use_simulith_endpoint" {
  description = "When true, route DynamoDB and SQS API calls to Simulith; when false, use real AWS"
  type        = bool
  default     = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "table_name" {
  description = "DynamoDB table name for event records"
  type        = string
  default     = "events-fanout-tf"
}

variable "queue_name" {
  description = "SQS queue name for async fan-out notifications"
  type        = string
  default     = "events-fanout-tf-queue"
}
