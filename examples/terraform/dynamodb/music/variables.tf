variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint (same host:port as CLI --endpoint-url)"
  type        = string
  default     = "http://127.0.0.1:4566"
}

variable "aws_region" {
  description = "AWS region passed to the provider"
  type        = string
  default     = "us-east-1"
}

variable "table_name" {
  description = "DynamoDB table name to create"
  type        = string
  default     = "Music-tf"
}
