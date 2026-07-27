variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint when use_simulith_endpoint is true"
  type        = string
  default     = "http://127.0.0.1:9080/runtime"
}

variable "use_simulith_endpoint" {
  description = "When true, route S3 and Lambda to Simulith"
  type        = bool
  default     = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type    = string
  default = "s3-lambda-tf-bucket"
}

variable "function_name" {
  type    = string
  default = "s3-event-processor-tf"
}

variable "lambda_role_arn" {
  type    = string
  default = "arn:aws:iam::000000000000:role/simulith-s3-lambda-tf"
}

variable "marker_dir" {
  description = "Local marker directory for handler verification (demo only)"
  type        = string
  default     = "/tmp/simulith-s3-lambda-tf"
}
