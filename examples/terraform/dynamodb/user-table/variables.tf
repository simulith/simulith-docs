################################################################################
# Optional variables — defaults work for Simulith local apply.
# Override via terraform.tfvars or -var / -var-file.
################################################################################

variable "simulith_endpoint" {
  description = "Simulith HTTP endpoint when use_simulith_endpoint is true. Docker all-in-one (Console :9080): http://127.0.0.1:9080/runtime. Native or published :4566: http://127.0.0.1:4566"
  type        = string
  default     = "http://127.0.0.1:9080/runtime"
}

variable "use_simulith_endpoint" {
  description = "When true, route DynamoDB API calls to Simulith; when false, use real AWS"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region passed to the provider"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Platform / project prefix for table name (e.g. demoapp → demoapp_user)"
  type        = string
  default     = "demoapp"
}

variable "environment" {
  description = "Environment name (dev, staging, prod). prod enables PITR and deletion protection."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}
