locals {
  environment = var.environment
  name_prefix = "${var.project_name}-${local.environment}"
}
