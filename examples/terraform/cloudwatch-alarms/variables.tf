variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint when use_simulith_endpoint is true. All-in-one: http://127.0.0.1:9080/runtime. Native: http://127.0.0.1:4566"
  type        = string
  default     = "http://127.0.0.1:9080/runtime"
}

variable "use_simulith_endpoint" {
  description = "When true, route CloudWatch (monitoring) API calls to Simulith; when false, use real AWS"
  type        = bool
  default     = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "alarm_name" {
  description = "CloudWatch metric alarm name"
  type        = string
  default     = "demo-tf-alarm"
}

variable "metric_name" {
  description = "Metric to watch"
  type        = string
  default     = "CPUUtilization"
}

variable "metric_namespace" {
  description = "Metric namespace"
  type        = string
  default     = "AWS/EC2"
}

variable "threshold" {
  description = "Alarm threshold"
  type        = number
  default     = 80
}
