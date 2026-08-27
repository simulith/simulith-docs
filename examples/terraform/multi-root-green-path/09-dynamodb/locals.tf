locals {
  environment = var.environment
  is_prod     = local.environment == "prod"
  table_name  = "${var.project_name}_user"
}
