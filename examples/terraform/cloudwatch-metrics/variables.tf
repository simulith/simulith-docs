variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint when use_simulith_endpoint is true. All-in-one: http://127.0.0.1:9080/runtime. Native: http://127.0.0.1:4566"
  type        = string
  default     = "http://127.0.0.1:9080/runtime"
}

variable "use_simulith_endpoint" {
  description = "When true, route CloudWatch Metrics API calls to Simulith; when false, use real AWS"
  type        = bool
  default     = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "metric_namespace" {
  description = "CloudWatch Metrics namespace"
  type        = string
  default     = "Simulith/Terraform"
}

variable "metric_name" {
  description = "Custom metric name published on apply"
  type        = string
  default     = "DemoLatency"
}

variable "metric_value" {
  description = "Datapoint value for PutMetricData"
  type        = number
  default     = 42
}
